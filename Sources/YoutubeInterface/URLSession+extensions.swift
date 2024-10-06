//
//  File.swift
//  YoutubeInterface
//
//  Created by Sumit Pradhan on 05/10/24.
//

import Foundation
import os
import SwiftSoup

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
  
  func getRequestPayload() async -> Result<[String: Any], any Error> {
    guard let url = URL(string: HTTPMusicAPIPaths.requestPayload.rawValue) else {
      return .failure(YoutubeInterfaceURLSessionError.invalidURL)
    }
    
    let request = URLRequest(url: url, timeoutInterval: 10)
    do {
      let (data, response) = try await data(for: request)
      guard let response = response as? HTTPURLResponse else {
        os_log("Invalid response from server", log: Logger.networking, type: .error)
        return .failure(YoutubeInterfaceURLSessionError.invalidResponse)
      }
      
      guard response.statusCode == 200 else {
        os_log("Invalid status code %d", log: Logger.networking, type: .error, response.statusCode)
        return .failure(YoutubeInterfaceURLSessionError.invalidStatusCode(response.statusCode))
      }
      
      guard let htmlString = String(data: data, encoding: .utf8) else {
        os_log("Unable to parse HTML string %{public}s", log: Logger.networking, type: .error, url.absoluteString)
        return .failure(YoutubeInterfaceURLSessionError.invalidData)
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
        let jsonEndRange = jsonSuffix.range(of: ");")
        let jsonString = jsonSuffix[..<jsonEndRange!.lowerBound]
        guard let json = try? JSONSerialization.jsonObject(with: String(jsonString).data(using: .utf8)!) as? [String: Any] else {
          return nil
        }
        return json["INNERTUBE_CONTEXT"] as? [String: Any]
      }
      
      guard let context, !context.isEmpty else {
        return .failure(YoutubeInterfaceURLSessionError.invalidData)
      }
      let contextWrap: [String: Any] = [
        "context": context.first! as [String: Any],
        "continuation": "4qmFsgKzAxIPRkV3aGF0X3RvX3dhdGNoGoIDaWdNVU1oSkZaMGxKUkhodlJsUllWbnBoVjAwbE0wVENCSVFDUjBreWQzWTFNazR0V1dkRVYyMHdTMkYzYjFwbFdGSm1ZMGRHYmxwV09YcGliVVozWXpKb2RtUkdPWGxhVjJSd1lqSTFhR0pDU1daamVrNWhZa1JzY1ZsV1VqRk5WM1JaVkZWc1dGSlZkRXRVUkU1NFRGVkdWbU5ITlhwVFJYQnZZWGh2ZEVGQlFteGlhVEZJVVdkQlFsTlZORUZCVld4UFFVRkZRVkpyVmpOaFIwWXdXRE5TZGxnelpHaGtSMDV2UVVGRlFrRlJRVUZCVVVGQlFWRkZRVmxyUlVsQlFrbFVXbTFzYzJSSFZubGFWMUptWTBkR2JscFdPVEJpTW5Sc1ltaHZWRU5NY1Uxb05USk9MVmxuUkVabWFGZHVVV3RrWDNoamQxSlRTVlJEVEhGTmFEVXlUaTFaWjBSR1ptaFhibEZyWkY5NFkzZFNaSEkyZWpWUlMwRm5aMEUlM0SaAhpicm93c2UtZmVlZEZFd2hhdF90b193YXRjaA%3D%3D"
      ]
      return .success(contextWrap)
    } catch {
      os_log("Error making API request", log: Logger.networking, type: .error)
      return .failure(YoutubeInterfaceURLSessionError.errorInApiRequest(error.localizedDescription))
    }
  }
  
  func getHomeScreenMusicList() async {
    guard let url = URL(string: HTTPMusicAPIPaths.homeScreenMusicList.rawValue) else {
      return
    }
    
    var request = URLRequest(url: url, timeoutInterval: 10)
    request.httpMethod = "POST"
    
    let result = await getRequestPayload()
    
    switch result {
    case .success(let payload):
      print("Hello")
    case .failure(let error):
      print("Error")
    }
    do {
      let (data, response) = try await data(for: request)
      guard let response = response as? HTTPURLResponse else {
        os_log("Invalid response from server", log: Logger.networking, type: .error)
        //        return .failure(YoutubeInterfaceURLSessionError.invalidResponse)
        return
      }
      
      guard response.statusCode == 200 else {
        os_log("Invalid status code %d", log: Logger.networking, type: .error, response.statusCode)
        //        return .failure(YoutubeInterfaceURLSessionError.invalidStatusCode(response.statusCode))
        return
      }
      
      guard let json = try? JSONSerialization.jsonObject(with: data) else {
        os_log("Invalid JSON for parsing music items", log: Logger.networking, type: .error)
        return
      }
      
      print(json)
    } catch {
      os_log("Error making API request %{public}s", log: Logger.networking, type: .error, #function)
    }
  }
}


