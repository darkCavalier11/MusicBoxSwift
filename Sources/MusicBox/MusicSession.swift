//
//  MusicSession.swift
//  MusicBox
//
//  Created by Sumit Pradhan on 19/10/24.
//
import Foundation

public protocol MusicSession: Sendable {
  func getHomeScreenMusicList() async -> [MusicItem]
  func getTypeAheadSearchResult(query: String) async -> [String]
  func getMusicSearchResults(query: String) async -> [MusicItem]
  func getMusicStreamingURL(musicId: String) async -> URL?
  func getNextSuggestedMusicItems(musicId: String) async -> [MusicItem]
}
