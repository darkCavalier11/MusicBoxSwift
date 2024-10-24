//
//  File.swift
//  MusicBox
//
//  Created by Sumit Pradhan on 24/10/24.
//

import Foundation

public struct MusicPlaylist {
  public let items: [MusicItem]
  public var totalDurationInSeconds: Int {
    items.reduce(0) { $0 + $1.runningDurationInSeconds }
  }
  
  public var top3ArtistNames: [String] {
    var top3ArtistNames: [String] = []
    for (idx, item) in items.enumerated() {
      if idx >= 3 { break }
      top3ArtistNames.append(item.publisherTitle)
    }
    return top3ArtistNames
  }
  
  public var top3ThumbnailURLs: [URL] {
    var top3ThumbnailURLs: [URL] = []
    for (idx, item) in items.enumerated() {
      if top3ThumbnailURLs.count == 3 { break }
      guard let thumbnailURL = URL(string: item.smallestThumbnail) else {
        continue
      }
      top3ThumbnailURLs.append(thumbnailURL)
    }
    return top3ThumbnailURLs
  }
  
  init (items: [MusicItem]) {
    self.items = items
  }
}
