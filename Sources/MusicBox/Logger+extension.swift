//
//  File.swift
//  MusicBox
//
//  Created by Sumit Pradhan on 19/10/24.
//

import Foundation
import os

extension Logger {
  func recordFileAndFunction(file: StaticString = #file, function: StaticString = #function) {
    debug("\(file, privacy: .public) : \(function, privacy: .public)")
  }
}
