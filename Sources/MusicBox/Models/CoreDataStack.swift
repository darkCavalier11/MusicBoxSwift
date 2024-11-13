//
//  File.swift
//  MusicBox
//
//  Created by Sumit Pradhan on 15/10/24.
//

import Foundation
import CoreData
import os

fileprivate let logger = Logger(subsystem: "com.youtube.interface", category: "CoreDataStack")

class CoreDataStack {
  private let modelName: String
  
  init(modelName: String) {
    self.modelName = modelName
  }
  
  private lazy var storeContainer: NSPersistentContainer = {
    let bundle = Bundle.module
    let moduleURL = bundle.url(forResource: modelName, withExtension: "mom")!
    let model = NSManagedObjectModel(contentsOf: moduleURL)!
    let container = NSPersistentContainer(name: modelName, managedObjectModel: model)
    container.loadPersistentStores { _, error in
      if let error {
        logger.error("Failed to load persistent stores: \(error)")
      }
    }
    print(container)
    return container
  }()
  
  lazy var managedObjectContext: NSManagedObjectContext = {
    self.storeContainer.viewContext
  }()
  
  func saveContext() {
    guard managedObjectContext.hasChanges else { return }
    do {
      _ = try managedObjectContext.save()
    } catch let error as NSError {
      logger.error("Unresolved error \(error), \(error.userInfo)")
    }
  }
}
