//
//  String+extension.swift
//  MusicBox
//
//  Created by Sumit Pradhan on 19/10/24.
//
import Foundation

extension String {
  var asciiDict: [String: String] {
    var d = [String: String]()
    for i in 30..<128 {
      let scalar = UnicodeScalar(i)
      let x = String(i, radix: 16)
      d["\\x" + x] = String(scalar!)
    }
    return d
  }
  
  /// Converts standart string duration into integer`01:30 -> 90` and
  /// `01:02:03 -> 3723`
  func convertDurationStringToSeconds() -> Int {
    let components = self.split(separator: ":").reversed()
    var totalDurationInSeconds = 0
    
    for (index, component) in components.enumerated() {
      let componentValue = Int(component) ?? 0
      totalDurationInSeconds += componentValue * Int(powl(60, Double(index)))
    }
    return totalDurationInSeconds
  }
  
  func replaceAllHexOccurances() -> String {
    var newValue = self
    for (key, value) in asciiDict {
      newValue = newValue.replacingOccurrences(of: key, with: value)
    }
    return newValue
  }
}
