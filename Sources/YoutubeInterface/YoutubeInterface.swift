// The Swift Programming Language
// https://docs.swift.org/swift-book
import SwiftSoup
import Foundation
import os

enum YoutubeInterfaceURL: String {
  case config = "https://www.youtube.com/"
}

protocol InternalConfigurationRequestManager {
  func getRequestHeader() async -> Result<[String: Any], any Error>
}

struct Logger {
  static let networking = OSLog(subsystem: "api.youtube.interface", category: "networking")
}

struct YoutubeInterface {
  let internalConfigurationRequestManager: InternalConfigurationRequestManager
  
  init(internalConfigurationRequestManager: InternalConfigurationRequestManager = URLSession.shared) {
    self.internalConfigurationRequestManager = internalConfigurationRequestManager
  }
}


