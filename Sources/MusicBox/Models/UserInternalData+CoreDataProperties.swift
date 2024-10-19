//
//  UserInternalData+CoreDataProperties.swift
//  MusicBox
//
//  Created by Sumit Pradhan on 19/10/24.
//
//

import Foundation
import CoreData


extension UserInternalData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserInternalData> {
        return NSFetchRequest<UserInternalData>(entityName: "UserInternalData")
    }

    @NSManaged public var payload: Data?

}
