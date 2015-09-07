//
//  Investor.swift
//  Earn the Green
//
//  Created by Owen LaRosa on 8/25/15.
//  Copyright (c) 2015 Owen LaRosa. All rights reserved.
//

import Foundation
import CoreData

@objc(Investor)

/// Earn the Green Investor entity. This class represents an investor object and provides statistics based on their assets. Each instance should be given a unique numeric identifier to distinguish it from the others.
class Investor: NSManagedObject {
    
    /// Unique numeric identifier for each instance. Zero (0) is reserved for the user.
    @NSManaged var identifier: Int
    
    /// Name of the investor.
    @NSManaged var name: String
    
    /// The income of the investor. If an Investor instance requires an income stream, use this property to store the income in the database.
    @NSManaged var income: Float
    
    /// Portfolio owned by the investor.
    @NSManaged var portfolio: Portfolio
    
    /// The investor's reason for investing. Use this property to display more information about the instance.
    @NSManaged var objective: String
    
    /// Represents the assets on the investor's watchlist. Only relevant for the user.
    @NSManaged var watchlist: NSOrderedSet
    
    // MARK: - Investor statistics
    
    /// Running total of the number of trades (buys and sells) made by the investor.
    @NSManaged var trades: Int
    
    /// Combined value of all the investor's assets.
    var netWorth: Float {
        return valueOfStocks + valueOfCash
    }
    
    /// Combined value of all stock owned by the investor.
    var valueOfStocks: Float {
        var money = Float(0.0)
        for i in portfolio.shares {
            let share = i as! OwnedShare
            let valueOfShares = share.stock.askingPrice * Float(share.quantity)
            money += valueOfShares
        }
        return money
    }
    
    /// Amount of cash in the investor's portfolio.
    var valueOfCash: Float {
        return portfolio.money
    }
    
    /// Total number of shares owned by the investor.
    var numberOfShares: Int {
        var number = 0
        for i in portfolio.shares {
            let share = i as! OwnedShare
            number += share.quantity
        }
        return number
    }
    
    /// Total number of different assets owned by the investor. E.g. The total number of companies in which the investor owns stock.
    var numberOfDifferentAssets: Int {
        return portfolio.shares.count
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(identifier: Int, name: String, income: Float, objective: String, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Investor", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.identifier = identifier
        self.name = name
        self.income = income
        self.objective = objective
    }
    
}
