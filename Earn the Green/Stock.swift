//
//  Stock.swift
//  Earn the Green
//
//  Created by Owen LaRosa on 8/25/15.
//  Copyright (c) 2015 Owen LaRosa. All rights reserved.
//

import Foundation
import CoreData

@objc(Stock)

/// Earn the Green Stock entity. This class stored up-to-date market data for the given stock. Data is initialized from a dictionary based on the JSON data from Yahoo Finance.
class Stock: NSManagedObject {
    
    /// Current listed price of a share.
    @NSManaged var askingPrice: Float
    
    /// Percent change up or down from the opening price.
    @NSManaged var percentChange: String
    
    /// Total value of dividends paid yearly.
    @NSManaged var dividendYield: Float
    
    /// Number of trades involving this stock since the opening bell.
    @NSManaged var volume: Int
    
    /// Lowest listed price for current trading hours.
    @NSManaged var low: Float
    
    /// Highest listed price for current trading hours.
    @NSManaged var high: Float
    
    /// Last time the data has been refreshed. For read-only use.
    @NSManaged var lastChanged: NSDate
    
    /// Company entity associated with the Stock.
    @NSManaged var company: Company
    
    /// OwnedShare entities across all portfolios that are associated with this stock.
    @NSManaged var shares: NSMutableSet
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(properties: [String : AnyObject], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Stock", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        updateData(properties)
    }
    
    func updateData(properties: [String : AnyObject]) {
        askingPrice = NSNumberFormatter().numberFromString(properties["Ask"] as! String) as! Float
        
        if properties["PercentChange"] as? NSNull != NSNull() {
            let percentChange = properties["PercentChange"] as! String
            let numberString = percentChange.substringWithRange(Range<String.Index>(start: percentChange.startIndex.advancedBy(1), end: percentChange.endIndex.advancedBy(-1)))
            self.percentChange = "\(percentChange.substringToIndex(percentChange.startIndex.advancedBy(1)))\(NSNumberFormatter().numberFromString(numberString) as! Float)%"
        } else {
            percentChange = "+0.0%"
        }
        
        if properties["DividendYield"] as? NSNull != NSNull() {
            let dividendYield = NSNumberFormatter().numberFromString(properties["DividendYield"] as! String) as! Float
            self.dividendYield = dividendYield
        } else {
            self.dividendYield = 0.0
        }
        
        if properties["DaysLow"] as? NSNull != NSNull() {
            let low = NSNumberFormatter().numberFromString(properties["DaysLow"] as! String) as! Float
            self.low = low
        } else {
            self.low = -1.0
        }
        
        if properties["DaysHigh"] as? NSNull != NSNull() {
            let high = NSNumberFormatter().numberFromString(properties["DaysHigh"] as! String) as! Float
            self.high = high
        } else {
            self.high = -1.0
        }
        
        if properties["Volume"] as? NSNull != NSNull() {
            let volume = NSNumberFormatter().numberFromString(properties["Volume"] as! String) as! Int
            self.volume = volume
        } else {
            self.volume = 0
        }
        
        lastChanged = NSDate()
    }
    
}