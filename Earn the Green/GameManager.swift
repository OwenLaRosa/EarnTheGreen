//
//  GameManager.swift
//  Earn the Green
//
//  Created by Owen LaRosa on 8/7/15.
//  Copyright (c) 2015 Owen LaRosa. All rights reserved.
//

import Foundation
import CoreData
import UIKit

/// Helper class that handles any game events and background tasks for game data.
class GameManager: NSObject {
    
    var context: NSManagedObjectContext {
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return delegate.managedObjectContext!
    }
    
    /// cache of all Stock entities in Core Data.
    lazy var stocks: [Stock] = {
        let fetchRequest = NSFetchRequest(entityName: "Stock")
        let stocks = self.context.executeFetchRequest(fetchRequest, error: nil) as! [Stock]
        return stocks
        }()
    
    /// Reference to the user's Investor entity.
    lazy var user: Investor = {
        let fetchRequest = NSFetchRequest(entityName: "Investor")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "identifier", ascending: true)]
        
        return self.context.executeFetchRequest(fetchRequest, error: nil)![0] as! Investor
        }()
    
    /// Day before which shares must be purchased to be eligible for the next dividend payment.
    var exDividendDate: NSDate? {
        get {
            return NSUserDefaults.standardUserDefaults().objectForKey("exDividendDate") as? NSDate
        }
        set(newDate) {
            NSUserDefaults.standardUserDefaults().setObject(newDate, forKey: "exDividendDate")
            //self.exDividendDate = newDate
        }
    }
    
    /// Day in which dividend payments will be processed.
    var dividendPayDate: NSDate? {
        get {
            return NSUserDefaults.standardUserDefaults().objectForKey("dividendPayDate") as? NSDate
        }
        set(newDate) {
            NSUserDefaults.standardUserDefaults().setObject(newDate, forKey: "dividendPayDate")
            //self.dividendPayDate = newDate
        }
    }
    
    /// Update loop for refreshing stock data in the background.
    var updateStockDataTimer = NSTimer()
    
    /// Returns true if a Stock entity with the specified ticker exists. Otherwise, returns false.
    func stockExistsForTicker(ticker: String) -> Bool {
        for i in stocks {
            if i.company.symbol == ticker {
                return true
            }
        }
        return false
    }
    
    /// If it exists, returns the Stock entity for the specified ticker. Otherwise, returns false.
    func getStockForTicker(ticker: String) -> Stock? {
        for i in stocks {
            if i.company.symbol == ticker {
                return i
            }
        }
        return nil
    }
    
    /// Starts the update loop for refreshing stock data.
    func startStockDataTimer() {
        updateStockDataTimer = NSTimer.scheduledTimerWithTimeInterval(30.0, target: GameManager.sharedInstance(), selector: "stockDataUpdateLoop", userInfo: nil, repeats: true)
    }
    
    /// Updates the data for a random stock in the user's portfolio.
    func stockDataUpdateLoop() {
        println("stockDataUpdateLoop")
        let shares = user.portfolio.shares.allObjects as! [OwnedShare]
        if shares.count != 0 {
            let share = shares[Int(arc4random() % UInt32(shares.count))]
            Helpers().updateStockData(share.stock) {success, error in
                
            }
            //if stock.shares.count == 0 {
            //    println("nothing to refresh here")
            //} else {
            //    println("continue and refresh: \(stock)")
                /*Helpers().updateStockData(stock) {success, error in
                if success {
                // broadcast stock did change notification
                } else {
                println(error)
                }
                }*/
            //}
        }
    }
    
    /// Early implementation of dividend payments. Should only process payments once per quarter but requires more testing for all possible cases.
    func processDividends(portflio: Portfolio) {
        if NSDate().compare(dividendPayDate!) == .OrderedDescending {
            // after pay date, process dividends
            var amount: Float = 0.0
            for i in (portflio.shares.allObjects as! [OwnedShare]) {
                amount += (Float(i.quantityForDividend) * i.stock.askingPrice / Float(4))
                i.quantityForDividend = i.quantity
            }
            portflio.money += amount
            let nextDividendDates = getNextDividendDates(dividendPayDate!)
            exDividendDate = nextDividendDates.exDate
            dividendPayDate = nextDividendDates.payDate
            processDividends(portflio)
        }
    }
    
    func getNextDividendDates(date: NSDate) -> (exDate: NSDate, payDate: NSDate) {
        var result = (exDate: NSDate(), payDate: NSDate())
        let year = date.getYear()
        switch date.getMonth() {
        case 1, 2, 3:
            if date.getMonth() == 1 && date.getDay() < 8 {
                let exDate = NSDate(month: 1, day: 1, year: year)
                let payDate = NSDate(month: 1, day: 8, year: year)
                result = (exDate: exDate, payDate: payDate)
            } else {
                let exDate = NSDate(month: 4, day: 1, year: year)
                let payDate = NSDate(month: 4, day: 8, year: year)
                result = (exDate: exDate, payDate: payDate)
            }
        case 4, 5, 6:
            if date.getMonth() == 4 && date.getDay() < 8 {
                let exDate = NSDate(month: 4, day: 1, year: year)
                let payDate = NSDate(month: 4, day: 8, year: year)
                result = (exDate: exDate, payDate: payDate)
            } else {
                let exDate = NSDate(month: 7, day: 1, year: year)
                let payDate = NSDate(month: 7, day: 8, year: year)
                result = (exDate: exDate, payDate: payDate)
            }
        case 7, 8, 9:
            if date.getMonth() == 7 && date.getDay() < 8 {
                let exDate = NSDate(month: 7, day: 1, year: year)
                let payDate = NSDate(month: 7, day: 8, year: year)
                result = (exDate: exDate, payDate: payDate)
            } else {
                let exDate = NSDate(month: 10, day: 1, year: year)
                let payDate = NSDate(month: 10, day: 8, year: year)
                result = (exDate: exDate, payDate: payDate)
            }
        case 10, 11, 12:
            if date.getMonth() == 10 && date.getDay() < 8 {
                let exDate = NSDate(month: 10, day: 1, year: year)
                let payDate = NSDate(month: 10, day: 8, year: year)
                result = (exDate: exDate, payDate: payDate)
            } else {
                let exDate = NSDate(month: 1, day: 1, year: year + 1)
                let payDate = NSDate(month: 1, day: 8, year: year + 1)
                result = (exDate: exDate, payDate: payDate)
            }
        default:
            break
        }
        return result
    }
    
    class func sharedInstance() -> GameManager {
        
        struct Singleton {
            static var sharedInstance = GameManager()
        }
        
        return Singleton.sharedInstance
    }
    
}

extension NSDate {
    
    convenience init(month: Int, day: Int, year: Int) {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = "\(year)-\(month)-\(day)"
        let date = formatter.dateFromString(dateString)!
        self.init(timeInterval: 0, sinceDate: date)
    }
    
    func getDay() -> Int {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "dd"
        let string = formatter.stringFromDate(self)
        return string.toInt()!
    }
    
    func getMonth() -> Int {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MM"
        let string = formatter.stringFromDate(self)
        return string.toInt()!
    }
    
    func getYear() -> Int {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "YYYY"
        let string = formatter.stringFromDate(self)
        return string.toInt()!
    }
    
}
