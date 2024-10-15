// The Swift Programming Language
// https://docs.swift.org/swift-book
import SwiftSoup
import Foundation
import os

protocol MusicSession {
  func getHomeScreenMusicList() async
  func getTypeAheadSearchResult(query: String) async -> [String]
  func getMusicSearchResults(query: String) async -> [MusicItem]
  func getMusicStreamingURL(musicId: String) async
}

struct YoutubeInterface {
  let musicSession: MusicSession
  
  init(musicSession: MusicSession = URLSession.shared) {
    self.musicSession = musicSession
  }
}


