//
//  File.swift
//  MusicBox
//
//  Created by Sumit Pradhan on 19/10/24.
//

import Foundation

struct HTTPMusicAPIPaths {
  static let requestPayload = "https://www.youtube.com/"
  static let homeScreenMusicList = "https://www.youtube.com/youtubei/v1/browse?prettyPrint=false"
  static func suggestionTypeAheadResults(query: String) -> String {
    "https://suggestqueries-clients6.youtube.com/complete/search?client=youtube&hl=en&gl=en&q=\(query)&callback=func"
  }
  static let musicSearchResults = "https://www.youtube.com/youtubei/v1/search?prettyPrint=false"
  static let logPlayEventForMusic = "https://www.youtube.com/youtubei/v1/player?prettyPrint=false"
  static let musicContinuationToken = "https://www.youtube.com/"
  static let getNextMusicItems = "https://www.youtube.com/youtubei/v1/next?prettyPrint=false"
}
