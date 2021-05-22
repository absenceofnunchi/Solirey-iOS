//
//  KeyWallet+CoreDataProperties.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-10.
//
//

import Foundation
import CoreData


extension KeyWallet {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<KeyWallet> {
        return NSFetchRequest<KeyWallet>(entityName: "KeyWallet")
    }

    @NSManaged public var address: String?
    @NSManaged public var data: Data?

}

extension KeyWallet : Identifiable {

}
