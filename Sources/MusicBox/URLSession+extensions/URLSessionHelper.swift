//
//  File.swift
//  YoutubeInterface
//
//  Created by Sumit Pradhan on 19/10/24.
//

import Foundation
import os
import SwiftSoup

extension URLSession {
  var coreDataStack : CoreDataStack {
    CoreDataStack(modelName: "MusicSessionModel")
  }
  
  var logger: Logger {
    Logger(subsystem: "com.youtube.interface", category: "Networking")
  }
  // TODO: remove public
  public func getClientRequestPayload() async -> [String: Any]? {
    logger.recordFileAndFunction()

    
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
        guard let context = json["INNERTUBE_CONTEXT"] as? [String: Any] else {
          return nil
        }
        guard var client = context["client"] as? [String: Any] else {
          return nil
        }
        /// Making client type to WEB instead of MWEB to
        /// 1. Home screen response will returns more music item
        /// 2. Same for paginated response
        client["clientName"] = "WEB"
        
        return [
          "context": [
            "client": client
          ]
        ]
      }
      
      guard let context, !context.isEmpty else {
        logger.error("\(#function) -> \(#line) -> Context request payload not found")
        return nil
      }
      if let data = try? JSONSerialization.data(withJSONObject: context.first) {
        UserInternalData.saveLatestUserRequestPayload(data, context: coreDataStack.managedObjectContext)
      }
      
      return context.first
    } catch {
      logger.error("\(#function) -> \(#line) -> Error making API request \(error.localizedDescription, privacy: .public)")
      return nil
    }
  }
  
  func getMusicContinuationToken(visitorId: String) async -> String? {
    logger.recordFileAndFunction()
    guard let url = URL(string: HTTPMusicAPIPaths.musicContinuationToken) else {
      return nil
    }
    
    var request = URLRequest(url: url)
    request.setValue(visitorId, forHTTPHeaderField: "X-Goog-Visitor-Id")
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
