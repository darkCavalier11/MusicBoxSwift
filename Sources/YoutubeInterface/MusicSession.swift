//
//  MusicSession.swift
//  YoutubeInterface
//
//  Created by Sumit Pradhan on 19/10/24.
//

protocol MusicSession {
  func getHomeScreenMusicList() async -> [MusicItem]
  func getTypeAheadSearchResult(query: String) async -> [String]
  func getMusicSearchResults(query: String) async -> [MusicItem]
  func getMusicStreamingURL(musicId: String) async
}
