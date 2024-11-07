//
//  CoreMusicRequest.swift
//  MusicBox
//
//  Created by Sumit Pradhan on 19/10/24.
//
import Foundation
import YouTubeKit

extension URLSession: MusicSession {
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
  
  func extractMusicItemFromVideoRenderer(videoRenderer: [String: Any]?) -> MusicItem? {
    let titleDict = videoRenderer?["title"] as? [String: Any]
    guard let runs = titleDict?["runs"] as? [[String: String]], runs.count > 0 else {
      return nil
    }
    
    let title = (runs[0]["text"]) ?? "-"
    
    let thumbnail = videoRenderer?["thumbnail"] as? [String: Any]
    let thumbnailList = thumbnail?["thumbnails"] as? [Any]
    
    let smallestThumbnail = (thumbnailList?.first as? [String: Any])?["url"] as? String
    let largestThumbnail = (thumbnailList?.last as? [String: Any])?["url"] as? String
    print(smallestThumbnail)
    print(largestThumbnail)
    
    let longBylineText = videoRenderer?["longBylineText"] as? [String: Any]
    guard let longRuns = longBylineText?["runs"] as? [[String: Any]], longRuns.count > 0 else {
      return nil
    }
    
    let publisherTitle = longRuns[0]["text"] as? String
    
    let lengthText = videoRenderer?["lengthText"] as? [String: Any]
    
    let runningDuration = lengthText?["simpleText"] as? String
    let runningDurationInSeconds = runningDuration?.convertDurationStringToSeconds() ?? -1
    
    let musicId = (videoRenderer?["videoId"] as? String) ?? "-"
    
    let musicItem = MusicItem(
      title: title,
      publisherTitle: publisherTitle ?? "-",
      runningDurationInSeconds: runningDurationInSeconds,
      musicId: musicId,
      smallestThumbnail: smallestThumbnail,
      largestThumbnail: largestThumbnail
    )
    
    return musicItem
  }
  
  
  public func getMusicStreamingURL(musicId: String) async -> URL?  {
    logger.recordFileAndFunction()
    let yt = YouTube(videoID: musicId)
    guard let streams = try? await yt.streams else {
      return nil
    }
    let audioTrack = streams
      .filterAudioOnly()
      .filter { $0.isNativelyPlayable }
      .filter { $0.fileExtension == .m4a }
      .highestAudioBitrateStream()
    
    await logPlaybackEvent(musicId: musicId)
    return audioTrack?.url
  }
  
  public func getNextSuggestedMusicItems(musicId: String) async -> [MusicItem] {
    logger.recordFileAndFunction()
    guard let url = URL(string: HTTPMusicAPIPaths.getNextMusicItems) else {
      return []
    }
    
    var request = URLRequest(url: url, timeoutInterval: 10)
    request.httpMethod = "POST"
    
    guard var result = await getClientRequestPayload() else {
      logger.error("\(#function) -> \(#line) -> Error getting request payload \(#function)")
      return []
    }
    guard let context = result["context"] as? [String: Any],
          let client = context["client"] as? [String: Any],
          let visitorId = client["visitorData"] as? String else {
      return []
    }
    result["videoId"] = musicId
    result["continuation"] = await getMusicContinuationToken(visitorId: visitorId)
    guard let httpBody = try? JSONSerialization.data(withJSONObject: result) else {
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
      guard let continuationContents = json["continuationContents"] as? [String: Any] else {
        logger.error("\(#function) -> \(#line) -> Invalid JSON for parsing continuation contents")
        return []
      }
      
      guard let watchNextSecondaryResultsContinuation = continuationContents["watchNextSecondaryResultsContinuation"] as? [String: Any] else {
        logger.error("\(#function) -> \(#line) -> Invalid JSON for parsing continuation watchNextSecondaryResultsContinuation")
        return []
      }
      
      guard let results = watchNextSecondaryResultsContinuation["results"] as? [[String:Any]] else {
        logger.error("\(#function) -> \(#line) -> Invalid JSON for parsing continuation results array")
        return []
      }
      
      let musicResults = results.compactMap { (item) -> [String: Any]? in
        guard let compactVideoRenderer = item["compactVideoRenderer"] as? [String: Any] else {
          return nil
        }
        return compactVideoRenderer
      }
     
      let musicItems = musicResults.compactMap { (videoRenderer) -> MusicItem? in
        let thumbnail = videoRenderer["thumbnail"] as? [String: Any]
        let thumbnailList = thumbnail?["thumbnails"] as? [Any]
        
        let smallestThumbnail = (thumbnailList?.first as? [String: Any])?["url"] as? String
        let largestThumbnail = (thumbnailList?.last as? [String: Any])?["url"] as? String
        
        let longBylineText = videoRenderer["longBylineText"] as? [String: Any]
        guard let longRuns = longBylineText?["runs"] as? [[String: Any]], longRuns.count > 0 else {
          return nil
        }
        let titleDict = videoRenderer["title"] as? [String: Any]
        guard let title = titleDict?["simpleText"] as? String else {
          return nil
        }
        guard let publisherTitle = longRuns[0]["text"] as? String else {
          return nil
        }
        
        let lengthText = videoRenderer["lengthText"] as? [String: Any]
        
        let runningDuration = lengthText?["simpleText"] as? String
        let runningDurationInSeconds = runningDuration?.convertDurationStringToSeconds() ?? -1
        
        guard let musicId = (videoRenderer["videoId"] as? String) else {
          return nil
        }
        
        let musicItem = MusicItem(
          title: title,
          publisherTitle: publisherTitle,
          runningDurationInSeconds: runningDurationInSeconds,
          musicId: musicId,
          smallestThumbnail: smallestThumbnail,
          largestThumbnail: largestThumbnail
        )
        return musicItem
      }
      return musicItems
    }
    catch {
      logger.error("Error loggin playback event \(error.localizedDescription)")
      return []
    }
  }
}
