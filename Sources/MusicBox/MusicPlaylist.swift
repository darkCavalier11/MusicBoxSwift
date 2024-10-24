//
//  File.swift
//  MusicBox
//
//  Created by Sumit Pradhan on 24/10/24.
//

import Foundation

public struct MusicPlaylist: Identifiable, Codable, Sendable {
  public let id: UUID
  public let title: String
  public var musicItems: [MusicItem]
  public var totalDurationInSeconds: Int {
    musicItems.reduce(0) { $0 + $1.runningDurationInSeconds }
  }
  
  public var top3ArtistNames: [String] {
    var top3ArtistNames: [String] = []
    for (idx, item) in musicItems.enumerated() {
      if idx >= 3 { break }
      top3ArtistNames.append(item.publisherTitle)
    }
    return top3ArtistNames
  }
  
  public var top3ThumbnailURLs: [URL] {
    var top3ThumbnailURLs: [URL] = []
    for (idx, item) in musicItems.enumerated() {
      if top3ThumbnailURLs.count == 3 { break }
      guard let thumbnailURL = URL(string: item.smallestThumbnail) else {
        continue
      }
      top3ThumbnailURLs.append(thumbnailURL)
    }
    return top3ThumbnailURLs
  }
  
  public mutating func addItemToPlaylist(_ item: MusicItem) -> Bool {
    if musicItems.contains(where: { $0.musicId == item.musicId }) {
      return false
    }
    return true
  }
  
  public init(id: UUID = UUID(), title: String, items: [MusicItem]) {
    self.id = id
    self.title = title
    self.musicItems = items
  }
}
