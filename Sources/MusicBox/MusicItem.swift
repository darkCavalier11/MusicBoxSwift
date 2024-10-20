//
//  File.swift
//  YoutubeInterface
//
//  Created by Sumit Pradhan on 07/10/24.
//

import Foundation

public struct MusicItem {
  let title: String
  let publisherTitle: String
  let runningDurationInSeconds: Int
  let musicId: String
  let smallestThumbnail: String
  let largestThumbnail: String
  
  static let defaultSmallestThumbnail = "https://img.icons8.com/?size=50&id=88618&format=png&color=000000"
  static let defaultLargestThumbnail = "https://img.icons8.com/?size=300&id=88618&format=png&color=000000"
  
  init(title: String,
       publisherTitle: String,
       runningDurationInSeconds: Int,
       musicId: String,
       smallestThumbnail: String?,
       largestThumbnail: String?
  ) {
    self.title = title
    self.publisherTitle = publisherTitle
    self.runningDurationInSeconds = runningDurationInSeconds
    self.musicId = musicId
    self.smallestThumbnail = smallestThumbnail ?? Self.defaultSmallestThumbnail
    self.largestThumbnail = largestThumbnail ?? Self.defaultLargestThumbnail
  }
}
