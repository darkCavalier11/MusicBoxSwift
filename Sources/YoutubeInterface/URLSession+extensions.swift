//
//  File.swift
//  YoutubeInterface
//
//  Created by Sumit Pradhan on 05/10/24.
//

import Foundation
import os
import SwiftSoup

fileprivate let logger = Logger(subsystem: "com.youtube.interface", category: "Networking")

extension Logger {
  func recordFileAndFunction(file: StaticString = #file, function: StaticString = #function) {
    debug("\(file, privacy: .public) : \(function, privacy: .public)")
  }
}

extension URLSession: MusicSession {
  enum YoutubeInterfaceURLSessionError: Error {
    case invalidURL
    case errorInApiRequest(String)
    case invalidResponse
    case invalidStatusCode(Int)
    case invalidData
    case parsingErrorInvalidHTML
    case notFoundParsingData
  }
  
  func getRequestPayload() async -> [String: Any]? {
    logger.recordFileAndFunction()
    guard let url = URL(string: HTTPMusicAPIPaths.requestPayload) else {
      return nil
    }
    
    let request = URLRequest(url: url, timeoutInterval: 10)
    do {
      let (data, response) = try await data(for: request)
      guard let response = response as? HTTPURLResponse else {
        logger.error("Invalid response from server")
        return nil
      }
      
      guard response.statusCode == 200 else {
        logger.error("Invalid status code \(response.statusCode, privacy: .public)")
        return nil
      }
      
      guard let htmlString = String(data: data, encoding: .utf8) else {
        logger.error("Unable to parse HTML string \(response.statusCode, privacy: .public)")
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
        logger.error("Context request payload not found")
        return nil
      }
      let contextWrap: [String: Any] = [
        "context": context.first! as [String: Any],
        "continuation": "4qmFsgKzAxIPRkV3aGF0X3RvX3dhdGNoGoIDaWdNVU1oSkZaMGxKUkhodlJsUllWbnBoVjAwbE0wVENCSVFDUjBreWQzWTFNazR0V1dkRVYyMHdTMkYzYjFwbFdGSm1ZMGRHYmxwV09YcGliVVozWXpKb2RtUkdPWGxhVjJSd1lqSTFhR0pDU1daamVrNWhZa1JzY1ZsV1VqRk5WM1JaVkZWc1dGSlZkRXRVUkU1NFRGVkdWbU5ITlhwVFJYQnZZWGh2ZEVGQlFteGlhVEZJVVdkQlFsTlZORUZCVld4UFFVRkZRVkpyVmpOaFIwWXdXRE5TZGxnelpHaGtSMDV2UVVGRlFrRlJRVUZCVVVGQlFWRkZRVmxyUlVsQlFrbFVXbTFzYzJSSFZubGFWMUptWTBkR2JscFdPVEJpTW5Sc1ltaHZWRU5NY1Uxb05USk9MVmxuUkVabWFGZHVVV3RrWDNoamQxSlRTVlJEVEhGTmFEVXlUaTFaWjBSR1ptaFhibEZyWkY5NFkzZFNaSEkyZWpWUlMwRm5aMEUlM0SaAhpicm93c2UtZmVlZEZFd2hhdF90b193YXRjaA%3D%3D"
      ]
      return contextWrap
    } catch {
      logger.error("Error making API request \(error.localizedDescription, privacy: .public)")
      return nil
    }
  }
  
  func getTypeAheadSearchResult(query: String) async -> [String] {
    logger.recordFileAndFunction()
    guard let url = URL(string: HTTPMusicAPIPaths.suggestionTypeAheadResults(query: query)) else {
      logger.error("Invalid URL for typeahead search \(URL(string: HTTPMusicAPIPaths.suggestionTypeAheadResults(query: query))?.absoluteString ?? "<None>", privacy: .public)")
      return []
    }
    
    let request = URLRequest(url: url)
    do {
      let (data, response) = try await data(for: request)
      guard let response = response as? HTTPURLResponse else {
        logger.error("Error getting response")
        return []
      }
      
      guard response.statusCode == 200 else {
        logger.error("Error getting response status code: \(response.statusCode)")
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
        logger.error("Error parsing JSON")
        return []
      }
      guard let metaList = json[1] as? [Any] else {
        logger.error("Error getting suggestions array")
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
      logger.error("Error making API request \(error.localizedDescription)")
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
    
    guard let result = await getRequestPayload() else {
      logger.error("Error getting request payload")
      return
    }
    
    guard let httpBody = try? JSONSerialization.data(withJSONObject: result) else {
      logger.error("Error converting request payload to Data()")
      return
    }
    
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = httpBody
    do {
      let (data, response) = try await data(for: request)
      guard let response = response as? HTTPURLResponse else {
        logger.error("Invalid response from server")
        return
      }
      
      guard response.statusCode == 200 else {
        logger.error("Invalid status code \(response.statusCode)")
        return
      }
      
      guard let json = try? JSONSerialization.jsonObject(with: data) else {
        logger.error("Invalid JSON for parsing music items")
        return
      }
    } catch {
      logger.error("Error making API request \(error.localizedDescription)")
    }
  }
}


