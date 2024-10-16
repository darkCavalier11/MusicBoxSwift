//
//  UserInternalData+CoreDataClass.swift
//  YoutubeInterface
//
//  Created by Sumit Pradhan on 15/10/24.
//
//

import Foundation
import CoreData
import os


public class UserInternalData: NSManagedObject {
  static private let logger = Logger(subsystem: "com.youtube.interface", category: "CoreDataStack")
  
  static func getLatestUserRequestPayload(context: NSManagedObjectContext) -> Data? {
    let request = UserInternalData.fetchRequest()
    let results = try? context.fetch(request)
    
    guard results != nil, results!.count > 0 else {
      logger.debug("Request payload not found in db")
      return nil
    }
    
    logger.debug("Found request \(results!.count) payload(s) in db")
    return results?.first?.payload
  }
  
  static func saveLatestUserRequestPayload(_ payload: Data, context: NSManagedObjectContext) {
    let userInternalData = UserInternalData(context: context)
    userInternalData.payload = payload
    logger.debug("Saving user internal data payload")
    try? context.save()
  }
}
