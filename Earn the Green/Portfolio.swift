//
//  Portfolio.swift
//  Earn the Green
//
//  Created by Owen LaRosa on 8/25/15.
//  Copyright (c) 2015 Owen LaRosa. All rights reserved.
//

import Foundation
import CoreData

@objc(Portfolio)

/// Earn the Green Portfolio entity. Class manages the portfolio of the specified Investor entity. Helper methods have been included to execute trades; however, you must first ensure that the trades are valid before calling them.
class Portfolio: NSManagedObject {
    
    /// Amount of money in cash contained in the porfolio.
    @NSManaged var money: Float
    
    /// All of the OwnedShare entities contained in the portfolio.
    @NSManaged var shares: NSMutableSet
    
    /// Investor entity that owns the portfolio.
    @NSManaged var investor: Investor
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(money: Float, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Portfolio", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.money = money
    }
    
    /// Adds the specified number of shares to the portfolio and subtracts the appropriate amount of money. Before calling, you should verify that the trade produces valid results.
    func buyStock(stock: Stock, quantity: Int, money: Float) {
        if let ownedShare = ownedShareForStock(stock) {
            ownedShare.quantity += quantity
            self.money -= money
            let currentDate = NSDate()
            if currentDate.compare(GameManager.sharedInstance().exDividendDate!) == .OrderedAscending {
                ownedShare.quantityForDividend += quantity
            }
        } else {
            let newShare = OwnedShare(quantity: quantity, context: sharedContext)
            newShare.stock = stock
            newShare.portfolio = self
            self.money -= money
            shares.addObject(newShare)
            stock.shares.addObject(newShare)
            let currentDate = NSDate()
            if currentDate.compare(GameManager.sharedInstance().exDividendDate!) == .OrderedAscending {
                newShare.quantityForDividend += quantity
            }
        }
        investor.trades += quantity
    }
    
    /// Subtracts the specified number of shares from the portfolio and adds the appropriate amount of money. Before calling, you should verify that the trade produces valid results.
    func sellStock(stock: Stock, quantity: Int, money: Float) {
        if let ownedShare = ownedShareForStock(stock) {
            // check number of dividend eligible shares to sell
            let difference = ownedShare.quantity - ownedShare.quantityForDividend
            if quantity > difference {
                ownedShare.quantityForDividend -= (quantity - difference)
            }
            // complete the transaction
            ownedShare.quantity -= quantity
            self.money += money
            if ownedShare.quantity == 0 {
                print("should remove")
                shares.removeObject(ownedShare)
                ownedShare.stock.shares.removeObject(ownedShare)
                sharedContext.deleteObject(ownedShare)
            }
        }
        investor.trades += quantity
    }
    
    /// Returns true if the portfolio contains shares of the specified stock. Otherwise, returns false.
    func hasShares(stock: Stock) -> Bool {
        var result = false
        for i in shares {
            let ownedShare = i as! OwnedShare
            if ownedShare.stock == stock {
                result = true
                break
            }
        }
        return result
    }
    
    func indexForStock(stock: Stock) -> Int {
        var count = 0
        for i in shares {
            if i.stock != stock {
                count++
            } else {
                return count
            }
        }
        return -1
    }
    
    /// Returns a reference to the OwnedShare entity contained in the porfolio that is associated with the specified stock. If no shares exist for the stock, returns nil.
    func ownedShareForStock(stock: Stock) -> OwnedShare? {
        for i in shares {
            let share = i as! OwnedShare
            if share.stock == stock {
                return share
            }
        }
        return nil
    }
    
}
