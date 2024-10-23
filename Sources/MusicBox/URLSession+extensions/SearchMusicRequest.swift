//
//  File.swift
//  MusicBox
//
//  Created by Sumit Pradhan on 19/10/24.
//

import Foundation

extension URLSession {
  public func getTypeAheadSearchResult(query: String) async -> [String] {
    logger.recordFileAndFunction()
    guard let url = URL(string: HTTPMusicAPIPaths.suggestionTypeAheadResults(query: query)) else {
      logger.error("\(#function) -> \(#line) -> Invalid URL for typeahead search \(URL(string: HTTPMusicAPIPaths.suggestionTypeAheadResults(query: query))?.absoluteString ?? "<None>", privacy: .public)")
      return []
    }
    
    let request = URLRequest(url: url)
    do {
      let (data, response) = try await data(for: request)
      guard let response = response as? HTTPURLResponse else {
        logger.error("\(#function) -> \(#line) -> Error getting response")
        return []
      }
      
      guard response.statusCode == 200 else {
        logger.error("\(#function) -> \(#line) -> Error getting response status code: \(response.statusCode)")
        return []
      }
      
      guard var scriptText = String(data: data, encoding: .utf8) else {
        return []
      }
      scriptText += "%%$$_______padding_________$$%%"
      guard let jsonBeginRange = scriptText.range(of: "func(") else {
        return []
      }
      let jsonSuffix = scriptText[jsonBeginRange.upperBound...]
      
      guard let jsonEndRange = jsonSuffix.range(of: ")%%$$_______padding_________$$%%") else {
        return []
      }
      let jsonString = jsonSuffix[..<jsonEndRange.lowerBound]
      guard let json = try? JSONSerialization.jsonObject(with: String(jsonString).data(using: .utf8)!) as? [Any] else {
        logger.error("\(#function) -> \(#line) -> Error parsing JSON")
        return []
      }
      guard let metaList = json[1] as? [Any] else {
        logger.error("\(#function) -> \(#line) -> Error getting suggestions array")
        return []
      }
      
      var suggestions: [String] = []
      for meta in metaList {
        guard let meta = meta as? [Any],
              meta.count > 0,
              let suggestion = meta[0] as? String
        else {
          continue
        }
        suggestions.append(suggestion)
      }
      return suggestions
    } catch {
      logger.error("\(#function) -> \(#line) -> Error making API request \(error.localizedDescription)")
      return []
    }
  }
  
  public func getMusicSearchResults(query: String) async -> [MusicItem] {
    logger.recordFileAndFunction()
    guard let url = URL(string: HTTPMusicAPIPaths.musicSearchResults) else {
      return []
    }
    
    var request = URLRequest(url: url, timeoutInterval: 10)
    request.httpMethod = "POST"
    
    guard var result = await getClientRequestPayload() else {
      logger.error("\(#function) -> \(#line) -> Error getting request payload \(#function)")
      return []
    }
    
    result["query"] = query
    guard let httpBody = try? JSONSerialization.data(withJSONObject: result) else {
      logger.error("\(#function) -> \(#line) -> Error converting request payload to Data()")
      return []
    }
    
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = httpBody
    
    do {
      let (data, response) = try await data(for: request)
      guard let response = response as? HTTPURLResponse else {
        logger.error("\(#function) -> \(#line) -> Invalid response from server")
        return []
      }
      
      guard response.statusCode == 200 else {
        logger.error("\(#function) -> \(#line) -> Invalid status code \(response.statusCode)")
        return []
      }
      
      guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        logger.error("\(#function) -> \(#line) -> Invalid JSON for parsing music items")
        return []
      }
      
      let parentContent = (json["contents"] as? [String: Any])
      
      let twoColumnSearchResultsRenderer = parentContent?["twoColumnSearchResultsRenderer"] as? [String: Any]
      let primaryContents = twoColumnSearchResultsRenderer?["primaryContents"] as? [String: Any]
      let sectionListRenderer = primaryContents?["sectionListRenderer"] as? [String: Any]
      guard let parentContents = sectionListRenderer?["contents"] as? [Any] else {
        logger.error("\(#function) -> \(#line) Error getting music list")
        return []
      }
      let itemSectionRenderer = (parentContents.first as? [String: Any])?["itemSectionRenderer"] as? [String: Any]
      guard let contents = itemSectionRenderer?["contents"] as? [Any] else {
        return []
      }
      var musicItems: [MusicItem] = []
      for musicContent in contents {
        guard let musicContent = musicContent as? [String: Any] else {
          continue
        }
        let videoRenderer = musicContent["videoRenderer"] as? [String: Any]
        
        guard let musicItem = extractMusicItemFromVideoRenderer(videoRenderer: videoRenderer) else {
          continue
        }
        
        musicItems.append(musicItem)
      }
      return musicItems
    } catch {
      logger.error("\(#function) -> \(#line) -> Error making API request \(error.localizedDescription)")
      return []
    }
  }
}
