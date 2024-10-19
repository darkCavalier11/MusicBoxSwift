// The Swift Programming Language
// https://docs.swift.org/swift-book
import SwiftSoup
import Foundation
import os


struct MusicBox {
  let musicSession: MusicSession
  
  init(musicSession: MusicSession = URLSession.shared) {
    self.musicSession = musicSession
  }
}