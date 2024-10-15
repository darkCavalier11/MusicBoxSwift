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

@objc(UserInternalData)
public class UserInternalData: NSManagedObject {
  private lazy var coreDataStack: CoreDataStack = {
    return CoreDataStack(modelName: "MusicSession")
  }()
  
  private let logger = Logger(subsystem: "com.youtube.interface", category: "CoreData/UserInternalData")
  
  func getLatestUserRequestPayload() -> Data? {
    let request = UserInternalData.fetchRequest()
    let results = try? coreDataStack.managedObjectContext.fetch(request)
    
    guard results != nil, results!.count > 0 else {
      logger.debug("Request payload not found in db")
      return nil
    }
    
    logger.debug("Found request payload in db")
    return results?.first?.payload
  }
  
  func saveLatestUserRequestPayload(_ payload: Data) {
    let userInternalData = UserInternalData(context: coreDataStack.managedObjectContext)
    userInternalData.payload = payload
    logger.debug("Saving user internal data payload")
    try? coreDataStack.managedObjectContext.save()
  }
}
