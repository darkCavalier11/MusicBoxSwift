//
//  File.swift
//  MusicBox
//
//  Created by Sumit Pradhan on 07/10/24.
//

import Foundation

public struct MusicItem: Equatable, Sendable, Codable {
  public let title: String
  public let publisherTitle: String
  public let runningDurationInSeconds: Int
  public let musicId: String
  public let smallestThumbnail: String
  public let largestThumbnail: String
  
  public static let defaultSmallestThumbnail = "https://img.icons8.com/?size=50&id=88618&format=png&color=000000"
  public static let defaultLargestThumbnail = "https://img.icons8.com/?size=300&id=88618&format=png&color=000000"
  
  public init(title: String,
      publisherTitle: String,
      runningDurationInSeconds: Int,
      musicId: String,
      smallestThumbnail: String? = nil,
      largestThumbnail: String? = nil
  ) {
    self.title = title
    self.publisherTitle = publisherTitle
    self.runningDurationInSeconds = runningDurationInSeconds
    self.musicId = musicId
    self.smallestThumbnail = smallestThumbnail ?? Self.defaultSmallestThumbnail
    self.largestThumbnail = largestThumbnail ?? Self.defaultLargestThumbnail
  }
}
