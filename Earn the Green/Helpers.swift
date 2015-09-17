//
//  Helpers.swift
//  Earn the Green
//
//  Created by Owen LaRosa on 8/11/15.
//  Copyright (c) 2015 Owen LaRosa. All rights reserved.
//

import Foundation
import CoreData
import UIKit

/// Helper methods for use across view controller classes.
struct Helpers {

    /// Returns a string representing the number in comma format.
    func formatNumberWithCommas(number: Int) -> String {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .DecimalStyle
        return formatter.stringFromNumber(NSNumber(integer: number))!
    }
    
    /// Returns a string representing the number as a money amount. Format is U.S. dollars.
    func formatNumberAsMoney(number: Float) -> String {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .CurrencyStyle
        return formatter.stringFromNumber(NSNumber(float: number))!
    }
    
    /// Returns a string representing the number as a percentage rounded to the ones place.
    func formatNumberAsPercentage(number: Float) -> String {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .PercentStyle
        return formatter.stringFromNumber(NSNumber(float: number))!
    }
    
    /// Returns "s" if the number is not equal to 1. Otherwise, returns an empty string.
    func pluralize(number: Int) -> String {
        if number == 1 {
            return ""
        } else {
            return "s"
        }
    }
    
    /// Refreshes the data for the given Stock entity. Completion handler tells if the update is successful and if not, provides an error message.
    func updateStockData(stock: Stock, completionHandler: (success: Bool, error: String?) ->  Void) -> NSURLSessionTask {
        let task = YahooFinance.sharedInstance().getInformationForTicker(stock.company.symbol) {data, error in
            if error != nil {
                completionHandler(success: false, error: error)
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    stock.updateData(data!)
                    completionHandler(success: true, error: nil)
                }
            }
        }
        return task
    }
    
    ///  Cancels all download tasks contained in the array.
    func cancelDownloadTasks(tasks: [NSURLSessionTask]) {
        for i in tasks {
            i.cancel()
        }
    }
    
    /// Returns true if the stock's price is up. Returns false if the price is down.
    func stockIsUp(stock: Stock) -> Bool {
        if NSString(string: stock.percentChange).substringToIndex(1) == "-" {
            return false
        } else {
            return true
        }
    }
    
    // allowed characters for search string
    let validCharacters = "abcdefghijklmnopqrstuvwxyz01234567890.,+!@&"
    
    /// Converts the search query into a string usable in HTTP requests.
    func formatStringForSearch(query: String) -> String {
        let input = query.lowercaseString
        var result = ""
        for i in input.characters {
            if validCharacters.characters.contains(i) {
                // only keep valid characters, invalid ones are ignored
                result += String(i)
            } else {
                if i == " " {
                    // URL safe character for separating words
                    result += "+"
                }
            }
        }
        return result
    }
    
    /// Toggles on the activity indicator in the status bar.
    func showNetworkActivity() {
        dispatch_async(dispatch_get_main_queue()) {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        }
    }
    
    /// Toggles off the activity indicator in the status bar.
    func hideNetworkActivity() {
        dispatch_async(dispatch_get_main_queue()) {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
    }
    
}
