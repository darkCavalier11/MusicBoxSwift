// The Swift Programming Language
// https://docs.swift.org/swift-book
import SwiftSoup
import Foundation
import os

enum HTTPMusicAPIPaths: String {
  case requestPayload = "https://www.youtube.com/"
  case homeScreenMusicList = "https://www.youtube.com/youtubei/v1/browse?prettyPrint=false"
}

protocol MusicSession {
  func getRequestPayload() async -> [String: Any]?
  func getHomeScreenMusicList() async
}

struct YoutubeInterface {
  let musicSession: MusicSession
  
  init(musicSession: MusicSession = URLSession.shared) {
    self.musicSession = musicSession
  }
}


