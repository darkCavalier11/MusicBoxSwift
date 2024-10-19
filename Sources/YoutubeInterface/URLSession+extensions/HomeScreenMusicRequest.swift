//
//  File.swift
//  YoutubeInterface
//
//  Created by Sumit Pradhan on 19/10/24.
//

import Foundation

extension URLSession {
  func getHomeScreenMusicList() async -> [MusicItem]  {
    logger.recordFileAndFunction()
    guard let url = URL(string: HTTPMusicAPIPaths.homeScreenMusicList) else {
      return []
    }
    
    var request = URLRequest(url: url, timeoutInterval: 10)
    request.httpMethod = "POST"
    
    guard var result = await getClientRequestPayload() else {
      logger.error("\(#function) -> \(#line) -> Error getting request payload")
      return []
    }
    
    guard let context = result["context"] as? [String: Any],
          let client = context["client"] as? [String: Any],
          let visitorId = client["visitorData"] as? String else {
      return []
    }
    let musicContinuationKey = await getMusicContinuationToken(visitorId: visitorId)
    
    result["continuation"] = musicContinuationKey
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
      
      guard let onResponseReceivedActions = json["onResponseReceivedActions"] as? [Any] else {
        return []
      }
      
      guard onResponseReceivedActions.count > 0, let primaryItem = onResponseReceivedActions.first as? [String: Any] else {
        return []
      }
      
      guard let reloadContinuationItemsCommand = primaryItem["reloadContinuationItemsCommand"] as? [String: Any] else {
        return []
      }
      
      guard let continuationItems = reloadContinuationItemsCommand["continuationItems"] as? [[String: Any]] else {
        return []
      }
      
      let musicItems = continuationItems.compactMap { (item) -> MusicItem? in
        let richItemRenderer = item["richItemRenderer"] as? [String: Any]
        let content = richItemRenderer?["content"] as? [String: Any]
        
        guard let videoRenderer = content?["videoRenderer"] as? [String: Any] else {
          return nil
        }
        
        let musicItem = extractMusicItemFromVideoRenderer(videoRenderer: videoRenderer)
        return musicItem
      }
      return musicItems
    } catch {
      logger.error("\(#function) -> \(#line) -> Error getting homescreen music items. \(error.localizedDescription)")
    }
    return []
  }
}
