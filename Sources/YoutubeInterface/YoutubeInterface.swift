// The Swift Programming Language
// https://docs.swift.org/swift-book
import SwiftSoup
import Foundation
import os

struct HTTPMusicAPIPaths {
  static let requestPayload = "https://www.youtube.com/"
  static let homeScreenMusicList = "https://www.youtube.com/youtubei/v1/browse?prettyPrint=false"
  static func suggestionTypeAheadResults(query: String) -> String {
    "https://suggestqueries-clients6.youtube.com/complete/search?client=youtube&hl=en&gl=en&q=\(query)&callback=func"
  }
  
}

protocol MusicSession {
  func getRequestPayload() async -> [String: Any]?
  func getHomeScreenMusicList() async
  func getTypeAheadSearchResult(query: String) async
}

struct YoutubeInterface {
  let musicSession: MusicSession
  
  init(musicSession: MusicSession = URLSession.shared) {
    self.musicSession = musicSession
  }
}

