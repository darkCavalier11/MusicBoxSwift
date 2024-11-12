// The Swift Programming Language
// https://docs.swift.org/swift-book
import SwiftSoup
import Foundation
import os

public struct MusicBox: Sendable {
  public let musicSession: MusicSession
  
  public init(musicSession: MusicSession = URLSession.shared) {
    self.musicSession = musicSession
  }
}
