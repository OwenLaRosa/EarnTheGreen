//
//  Company.swift
//  Earn the Green
//
//  Created by Owen LaRosa on 8/25/15.
//  Copyright (c) 2015 Owen LaRosa. All rights reserved.
//

import Foundation
import CoreData

@objc(Company)

/// Earn the Green Company entity. This class stores identifying information for a business or other entity that sells shares. The symbol property is used as a unique identifier for each entity. Each Company is associated with a Stock entity that contains information regarding the company's stock.
class Company: NSManagedObject {
    
    /// Official name of the company.
    @NSManaged var name: String
    
    /// Stock ticker for the company.
    @NSManaged var symbol: String
    
    /// Type of asset associated with the company.
    @NSManaged var type: String
    
    /// Information regarding the company's stock.
    @NSManaged var stock: Stock
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(properties: [String : AnyObject], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Company", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.name = properties["name"] as! String
        self.symbol = properties["symbol"] as! String
        self.type = properties["type"] as! String
    }
    
}