//
//  OwnedShare.swift
//  Earn the Green
//
//  Created by Owen LaRosa on 8/25/15.
//  Copyright (c) 2015 Owen LaRosa. All rights reserved.
//

import Foundation
import CoreData

@objc(OwnedShare)

/// Earn the Green OwnedShare entity. Used to keep track of the quantity of shares owned in a portfolio. Associated with the Portfolio entity that owns the shares.
class OwnedShare: NSManagedObject {
    
    /// Stock data associated with the object.
    @NSManaged var stock: Stock
    
    /// Number of shares owned.
    @NSManaged var quantity: Int
    
    /// Number of shares eligible for the next dividend payment. Shares purchased before the ex-dividend date will be excluded from this value until the next date is scheduled.
    @NSManaged var quantityForDividend: Int
    
    /// Portfolio in which the shares are contained.
    @NSManaged var portfolio: Portfolio
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(quantity: Int, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("OwnedShare", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.quantity = quantity
    }
    
}
