//
//  File.swift
//  YoutubeInterface
//
//  Created by Sumit Pradhan on 05/10/24.
//

import Foundation
import os
import SwiftSoup

private struct HTTPMusicAPIPaths {
  static let requestPayload = "https://www.youtube.com/"
  static let homeScreenMusicList = "https://www.youtube.com/youtubei/v1/browse?prettyPrint=false"
  static func suggestionTypeAheadResults(query: String) -> String {
    "https://suggestqueries-clients6.youtube.com/complete/search?client=youtube&hl=en&gl=en&q=\(query)&callback=func"
  }
  static let musicSearchResults = "https://www.youtube.com/youtubei/v1/search?prettyPrint=false"
  static let logPlayEventForMusic = "https://www.youtube.com/youtubei/v1/player?prettyPrint=false"
  static let musicContinuationToken = "https://www.youtube.com/"
}

extension Logger {
  func recordFileAndFunction(file: StaticString = #file, function: StaticString = #function) {
    debug("\(file, privacy: .public) : \(function, privacy: .public)")
  }
}

extension URLSession: MusicSession {
  private var coreDataStack : CoreDataStack {
    CoreDataStack(modelName: "MusicSessionModel")
  }
  
  private var logger: Logger {
    Logger(subsystem: "com.youtube.interface", category: "Networking")
  }
  
  
  enum YoutubeInterfaceURLSessionError: Error {
    case invalidURL
    case errorInApiRequest(String)
    case invalidResponse
    case invalidStatusCode(Int)
    case invalidData
    case parsingErrorInvalidHTML
    case notFoundParsingData
  }
  
  private func getClientRequestPayload() async -> [String: Any]? {
    logger.recordFileAndFunction()
    if let payloadData = UserInternalData.getLatestUserRequestPayload(context: coreDataStack.managedObjectContext) {
      let json = try? JSONSerialization.jsonObject(with: payloadData)
      return json as? [String: Any]
    }
    guard let url = URL(string: HTTPMusicAPIPaths.requestPayload) else {
      return nil
    }
    
    let request = URLRequest(url: url, timeoutInterval: 10)
    do {
      let (data, response) = try await data(for: request)
      guard let response = response as? HTTPURLResponse else {
        logger.error("\(#function) -> \(#line) -> Invalid response from server")
        return nil
      }
      
      guard response.statusCode == 200 else {
        logger.error("\(#function) -> \(#line) -> Invalid status code \(response.statusCode, privacy: .public)")
        return nil
      }
      
      guard let htmlString = String(data: data, encoding: .utf8) else {
        logger.error("\(#function) -> \(#line) -> Unable to parse HTML string \(response.statusCode, privacy: .public)")
        return nil
      }
      
      let htmlDocument = try? SwiftSoup.parse(htmlString)
      let body = htmlDocument?.body()
      let elements = try? body?.getElementsByTag("script")
      
      let context = elements?.compactMap { (scriptElement) -> [String: Any]? in
        guard let scriptText = try? scriptElement.html(), scriptText.contains("INNERTUBE_CONTEXT") else {
          return nil
        }
        guard let jsonBeginRange = scriptText.range(of: "{\"CLIENT_CANARY_STATE\"") else {
          return nil
        }
        let jsonSuffix = scriptText[jsonBeginRange.lowerBound...]
        guard let jsonEndRange = jsonSuffix.range(of: ");") else {
          return nil
        }
        let jsonString = jsonSuffix[..<jsonEndRange.lowerBound]
        guard let json = try? JSONSerialization.jsonObject(with: String(jsonString).data(using: .utf8)!) as? [String: Any] else {
          return nil
        }
        return json["INNERTUBE_CONTEXT"] as? [String: Any]
      }
      
      guard let context, !context.isEmpty else {
        logger.error("\(#function) -> \(#line) -> Context request payload not found")
        return nil
      }
      let contextWrap: [String: Any] = [
        "context": context.first! as [String: Any],
      ]
      if let jsonData = try? JSONSerialization.data(withJSONObject: contextWrap, options: []) {
        UserInternalData.saveLatestUserRequestPayload(jsonData, context: coreDataStack.managedObjectContext)
      }
      return contextWrap
    } catch {
      logger.error("\(#function) -> \(#line) -> Error making API request \(error.localizedDescription, privacy: .public)")
      return nil
    }
  }
  
  func getTypeAheadSearchResult(query: String) async -> [String] {
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
  
  func getHomeScreenMusicList() async {
    logger.recordFileAndFunction()
    guard let url = URL(string: HTTPMusicAPIPaths.homeScreenMusicList) else {
      return
    }
    
    var request = URLRequest(url: url, timeoutInterval: 10)
    request.httpMethod = "POST"
    
    guard var result = await getClientRequestPayload() else {
      logger.error("\(#function) -> \(#line) -> Error getting request payload")
      return
    }
    
    let musicContinuationKey = await getMusicContinuationToken()
    print(musicContinuationKey)
//    result["continuation"] = musicContinuationKey
//    print(result)
    return
    guard let httpBody = try? JSONSerialization.data(withJSONObject: result) else {
      logger.error("\(#function) -> \(#line) -> Error converting request payload to Data()")
      return
    }
    
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = httpBody
    do {
      let (data, response) = try await data(for: request)
      guard let response = response as? HTTPURLResponse else {
        logger.error("\(#function) -> \(#line) -> Invalid response from server")
        return
      }
      
      guard response.statusCode == 200 else {
        logger.error("\(#function) -> \(#line) -> Invalid status code \(response.statusCode)")
        return
      }
      
      guard let _ = try? JSONSerialization.jsonObject(with: data) else {
        logger.error("\(#function) -> \(#line) -> Invalid JSON for parsing music items")
        return
      }
    } catch {
      logger.error("\(#function) -> \(#line) -> Error making API request \(error.localizedDescription)")
    }
  }
  
  func getMusicSearchResults(query: String) async -> [MusicItem] {
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
      let sectionListRenderer = parentContent?["sectionListRenderer"] as? [String: Any]
      let primaryContents = sectionListRenderer?["contents"] as? [Any]
      let itemSectionRenderer = (primaryContents?[0] as? [String: Any])?["itemSectionRenderer"] as? [String: Any]
      guard let contents = itemSectionRenderer?["contents"] as? [Any] else {
        logger.error("\(#function) -> \(#line) Error getting music list")
        return []
      }
      
      var musicItems: [MusicItem] = []
      for musicContent in contents {
        guard let musicContent = musicContent as? [String: Any] else {
          continue
        }
        let videoWithContextRenderer = musicContent["videoWithContextRenderer"] as? [String: Any]
        let headline = videoWithContextRenderer?["headline"] as? [String: Any]
        guard let runs = headline?["runs"] as? [[String: String]], runs.count > 0 else {
          continue
        }
        
        let title = (runs[0]["text"]) ?? "-"
        
        let thumbnail = videoWithContextRenderer?["thumbnail"] as? [String: Any]
        let thumbnailList = thumbnail?["thumbnails"] as? [Any]
        
        let smallestThumbnail = (thumbnailList?.first as? [String: Any])?["url"] as? String
        let largestThumbnail = (thumbnailList?.last as? [String: Any])?["url"] as? String
        
        let shortBylineText = videoWithContextRenderer?["shortBylineText"] as? [String: Any]
        guard let shortRuns = shortBylineText?["runs"] as? [[String: Any]], shortRuns.count > 0 else {
          continue
        }
        
        let publisherTitle = shortRuns[0]["text"] as? String
        
        let lengthText = videoWithContextRenderer?["lengthText"] as? [String: Any]
        guard let lengthRuns = lengthText?["runs"] as? [[String: Any]], lengthRuns.count > 0 else {
          continue
        }
        
        let runningDuration = lengthRuns[0]["text"] as? String
        let runningDurationInSeconds = runningDuration?.convertDurationStringToSeconds() ?? -1
        
        let musicId = (videoWithContextRenderer?["videoId"] as? String) ?? "-"
        
        let musicItem = MusicItem(
          title: title,
          publisherTitle: publisherTitle ?? "-",
          runningDurationInSeconds: runningDurationInSeconds,
          musicId: musicId,
          smallestThumbnail: smallestThumbnail ?? "https://img.icons8.com/?size=50&id=88618&format=png&color=000000",
          largestThumbnail: largestThumbnail ?? "https://img.icons8.com/?size=300&id=88618&format=png&color=000000"
        )
        
        musicItems.append(musicItem)
      }
      return musicItems
    } catch {
      logger.error("\(#function) -> \(#line) -> Error making API request \(error.localizedDescription)")
      return []
    }
  }
  
  func getMusicStreamingURL(musicId: String) async  {
    logger.recordFileAndFunction()
    // TODO: - Return music streaming URL
    await logPlaybackEvent(musicId: musicId)
  }
  
  private func logPlaybackEvent(musicId: String) async {
    logger.recordFileAndFunction()
    guard let url = URL(string: HTTPMusicAPIPaths.logPlayEventForMusic) else {
      return
    }
    
    var request = URLRequest(url: url, timeoutInterval: 10)
    request.httpMethod = "POST"
    
    guard var result = await getClientRequestPayload() else {
      logger.error("\(#function) -> \(#line) -> Error getting request payload \(#function)")
      return
    }
    
    result["videoId"] = musicId
    guard let httpBody = try? JSONSerialization.data(withJSONObject: result) else {
      return
    }
    
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = httpBody
    
    do {
      let (data, response) = try await data(for: request)
      guard let response = response as? HTTPURLResponse else {
        logger.error("\(#function) -> \(#line) -> Invalid response from server")
        return
      }
      
      guard response.statusCode == 200 else {
        logger.error("\(#function) -> \(#line) -> Invalid status code \(response.statusCode)")
        return
      }
      
      guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        logger.error("\(#function) -> \(#line) -> Invalid JSON for parsing music items")
        return
      }
      
      let playbackTracking = json["playbackTracking"] as? [String: Any]
      let statsPlaybackURL = playbackTracking?["videostatsPlaybackUrl"] as? [String: Any]
      
      guard var baseURLString = statsPlaybackURL?["baseUrl"] as? String else {
        logger.warning("Not able to log event because baseURL is missing from playback tracking")
        return
      }
      baseURLString.replaceSubrange(baseURLString.startIndex..<baseURLString.index(baseURLString.startIndex, offsetBy: 22), with: "https://www.youtube.com/")
      precondition(baseURLString.starts(with: "https://www.youtube.com"))
      
      guard var baseURL = URLComponents(string: baseURLString) else {
        logger.log("Invalid playback track URL \(baseURLString)")
        return
      }
      
      baseURL.queryItems?.append(.init(name: "sourceid", value: "ys"))
      baseURL.queryItems?.append(.init(name: "afmt", value: "251"))
      baseURL.queryItems?.append(.init(name: "cr", value: Locale.current.regionCode ?? "IN"))
      baseURL.queryItems?.append(.init(name: "hl", value: Locale.current.identifier))
      baseURL.queryItems?.append(.init(name: "muted", value: "0"))
      baseURL.queryItems?.append(.init(name: "ns", value: "yt"))
      baseURL.queryItems?.append(.init(name: "ver", value: "2"))
      
      guard let playbackTrackingURL = baseURL.url else {
        logger.log("Invalid playback track URL when added query \(baseURL)")
        return
      }
      let playbackTrackingURLRequest = URLRequest(url: playbackTrackingURL, timeoutInterval: 10)
      
      _ = try? await self.data(for: playbackTrackingURLRequest)
    }
    catch {
      logger.error("Error loggin playback event \(error.localizedDescription)")
    }
  }
  
  // TODO: - Refactor code for better parsing
  private func getMusicContinuationToken() async -> String? {
    logger.recordFileAndFunction()
    guard let url = URL(string: HTTPMusicAPIPaths.musicContinuationToken) else {
      return nil
    }
    
    var request = URLRequest(url: url)
    // TODO: - Remove debug header key
    request.setValue("Cgtfa0laMWZvTHlmYyjeiqS4BjIKCgJJThIEGgAgRA%3D%3D", forHTTPHeaderField: "X-Goog-Visitor-Id")
    guard let (data, response) = try? await self.data(from: url) else {
      return nil
    }
    
    guard let response = response as? HTTPURLResponse else {
      return nil
    }
    
    guard response.statusCode == 200 else {
      return nil
    }
    guard let htmlString = String(data: data, encoding: .utf8) else {
      return nil
    }
    
    let htmlDocument = try? SwiftSoup.parse(htmlString)
    let body = htmlDocument?.body()
    let elements = try? body?.getElementsByTag("script")
    let context = elements?.compactMap { (scriptElement) -> [String: Any]? in
      guard let scriptText = try? scriptElement.html(), scriptText.contains("responseContext") else {
        return nil
      }
      
      guard let jsonBeginRange = scriptText.range(of: "\\x7b\\x22responseContext\\x22:\\x7b") else {
        return nil
      }
      
      let jsonSuffix = scriptText[jsonBeginRange.lowerBound...]
      guard let jsonEndRange = jsonSuffix.range(of: "\\x7d';") else {
        return nil
      }
      var jsonString = String(jsonSuffix[..<jsonEndRange.lowerBound])
      jsonString += "\\x7d"
      jsonString = jsonString.replaceAllHexOccurances()
      
      guard let json = try? JSONSerialization.jsonObject(with: String(jsonString).data(using: .utf8)!) as? [String: Any] else {
        logger.error("Error parsing json getting music CONTINUATION key")
        return nil
      }
      
      guard let contents = json["contents"] as? [String: Any] else {
        logger.error("contents not found")
        return nil
      }
      
      guard let scbrRenderer = contents["singleColumnBrowseResultsRenderer"] as? [String: Any] else {
        logger.error("singleColumnBrowseResultsRenderer not found")
        return nil
      }
      
      guard let tabs = scbrRenderer["tabs"] as? [Any] else {
        logger.error("tabs not found")
        return nil
      }
      
      guard let tabRendererDict = tabs.first as? [String: Any] else {
        return nil
      }

      guard let tabRenderer = tabRendererDict["tabRenderer"] as? [String: Any] else {
        logger.error("tabRenderer not found")
        return nil
      }
      
      guard let tabContent = tabRenderer["content"] as? [String: Any] else {
        logger.error("tab content is empty")
        return nil
      }
      
      guard let richGridRenderer = tabContent["richGridRenderer"] as? [String: Any] else {
        logger.error("richGridRenderer is empty")
        return nil
      }
      
      guard let header = richGridRenderer["header"] as? [String: Any] else {
        logger.error("header not found")
        return nil
      }
      
      guard let feedFilterChipBarRenderer = header["feedFilterChipBarRenderer"] as? [String: Any] else {
        logger.error("feedFilterChipBarRenderer not found")
        return nil
      }
      
      guard let continuationContent = feedFilterChipBarRenderer["contents"] as? [[String: Any]] else {
        logger.error("continuationContent not found")
        return nil
      }
      // TODO: - Extract other continuation key for different other texts thats related to music like Asian music or artist name
      let musicItem = continuationContent.compactMap { item -> [String: Any]? in
        guard let chipCloudChipRenderer = item["chipCloudChipRenderer"] as? [String: Any] else {
          return nil
        }
        
        guard let text = chipCloudChipRenderer["text"] as? [String: Any] else {
          return nil
        }
        
        guard let runs = text["runs"] as? [[String: String]] else {
          return nil
        }
        
        guard let navigationEndpoint = chipCloudChipRenderer["navigationEndpoint"] as? [String: Any] else {
          return nil
        }
        
        guard let continuationCommand = navigationEndpoint["continuationCommand"] as? [String: Any] else {
          return nil
        }
        
        guard let token = continuationCommand["token"] as? String else {
          return nil
        }
        if runs.first?["text"] == "Music" {
          return ["token": token]
        }
        return nil
      }
      
      return musicItem.count > 0 ? musicItem.first : [:]
    }
    
    guard let context = context, context.count > 0, let token = context.first?["token"] as? String else {
      return nil
    }
    
    return token
  }
}

private extension String {
  /// 01:30 -> 90
  /// 01:02:03 -> 3723
  
  var asciiDict: [String: String] {
    var d = [String: String]()
    for i in 30..<128 {
      let scalar = UnicodeScalar(i)
      let x = String(i, radix: 16)
      d["\\x" + x] = String(scalar!)
    }
    return d
  }
  
  func convertDurationStringToSeconds() -> Int {
    let components = self.split(separator: ":").reversed()
    var totalDurationInSeconds = 0
    
    for (index, component) in components.enumerated() {
      let componentValue = Int(component) ?? 0
      totalDurationInSeconds += componentValue * Int(powl(60, Double(index)))
    }
    return totalDurationInSeconds
  }
  
  func replaceAllHexOccurances() -> String {
    var newValue = self
    for (key, value) in asciiDict {
      newValue = newValue.replacingOccurrences(of: key, with: value)
    }
    return newValue
  }
}
