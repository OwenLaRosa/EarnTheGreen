//
//  StockDetailViewController.swift
//  Earn the Green
//
//  Created by Owen LaRosa on 8/11/15.
//  Copyright (c) 2015 Owen LaRosa. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class StockDetailViewController: UIViewController {
    
    var context: NSManagedObjectContext {
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return delegate.managedObjectContext!
    }
    
    var stock: Stock!
    var portfolio: Portfolio!
    
    /// Determines if the data should be refreshed once the view appears.
    var shouldRefresh = false
    var downloadTasks = [NSURLSessionTask]()
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var companyView: UIView!
    
    @IBOutlet weak var buyStockView: UIView!
    
    @IBOutlet weak var sellStockView: UIView!
    
    @IBOutlet weak var companyNameLabel: UILabel!
    
    @IBOutlet weak var symbolLabel: UILabel!
    
    @IBOutlet weak var upDownLabel: UILabel!
    
    @IBOutlet weak var priceLabel: UILabel!
    
    @IBOutlet weak var volumeLabel: UILabel!
    
    @IBOutlet weak var highLowLabel: UILabel!
    
    @IBOutlet weak var dividendYieldLabel: UILabel!
    
    @IBOutlet weak var watchlistButton: UIButton!
    
    @IBOutlet weak var buySharesStepper: UIStepper!
    
    @IBOutlet weak var buySharesPriceLabel: UILabel!
    
    @IBOutlet weak var buySharesActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var sellSharesStepper: UIStepper!
    
    @IBOutlet weak var sellSharesPriceLabel: UILabel!
    
    @IBOutlet weak var ownedSharesLabel: UILabel!
    
    @IBOutlet weak var sellSharesActivityIndicator: UIActivityIndicatorView!
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // configure the scroll view
        let width = UIScreen.mainScreen().bounds.width
        let height = companyView.frame.height + buyStockView.frame.height + sellStockView.frame.height + 32
        scrollView.contentSize = CGSizeMake(width, height)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        configureUI()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if shouldRefresh {
            if NSDate().timeIntervalSinceDate(stock!.lastChanged) > 180.0 { // 3 minutes
                refreshData()
            }
        }
        shouldRefresh = false
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        Helpers().hideNetworkActivity()
    }
    
    @IBAction func refreshButtonTapped(sender: UIBarButtonItem) {
        refreshData()
    }
    
    @IBAction func watchlistButtonTapped(sender: UIButton) {
        var watchlist = portfolio.investor.watchlist.array as! [Stock]
        if let index = find(watchlist, stock!) {
            watchlist.removeAtIndex(index)
            sender.setTitle(" Add to Watchlist ", forState: .Normal)
        } else {
            watchlist.insert(stock!, atIndex: 0)
            sender.setTitle(" Remove from Watchlist ", forState: .Normal)
        }
        portfolio.investor.watchlist = NSOrderedSet(array: watchlist)
        saveContext()
    }
    
    @IBAction func buySharesButtonTapped(sender: UIButton) {
        // do nothing if 0 shares
        if buySharesStepper.value == 0.0 {
            return
        }
        Helpers().cancelDownloadTasks(downloadTasks)
        buySharesActivityIndicator.startAnimating()
        // update data to minimize cheating
        downloadTasks.append(Helpers().updateStockData(stock!) {success, error in
            if error != nil {
                self.buySharesActivityIndicator.stopAnimating()
                self.showUpdateError()
            } else {
                let quantity = Int(self.buySharesStepper.value)
                let totalPrice = self.stock.askingPrice * Float(self.buySharesStepper.value)
                if self.portfolio.money >= totalPrice { // user can afford this many shares
                    let confirmation = UIAlertController(title: "Confirm Purchase.", message: "Are you sure you want to buy \(quantity) shares of \(self.stock.company.symbol) for \(Helpers().formatNumberAsMoney(totalPrice))", preferredStyle: .Alert)
                    confirmation.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                    confirmation.addAction(UIAlertAction(title: "Purchase", style: .Default, handler: {(alert: UIAlertAction!) in
                        self.portfolio.buyStock(self.stock, quantity: quantity, money: totalPrice)
                        self.saveContext()
                        self.configureUI()
                    }))
                    self.buySharesActivityIndicator.stopAnimating()
                    self.presentViewController(confirmation, animated: true, completion: nil)
                } else { // user tried to buy more shares than they can afford
                    let alert = UIAlertController(title: "Purchase failed.", message: "You do not have enough money to buy \(Int(self.buySharesStepper.value)) shares of \(self.stock.company.name).", preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
                    self.buySharesActivityIndicator.stopAnimating()
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }
        })
    }
    
    @IBAction func buySharesStepperValueChanged(sender: UIStepper) {
        let number = Int(sender.value)
        let price = (stock.askingPrice * Float(number))
        buySharesPriceLabel.text = "\(Int(sender.value)) Share\(Helpers().pluralize(number)) for \(Helpers().formatNumberAsMoney(price))"
    }
    
    @IBAction func sellSharesButtonTapped(sender: UIButton) {
        if sellSharesStepper.value == 0.0 {
            return
        }
        Helpers().cancelDownloadTasks(downloadTasks)
        sellSharesActivityIndicator.startAnimating()
        // update data to minimize cheating
        downloadTasks.append(Helpers().updateStockData(stock!) {success, error in
            if error != nil {
                self.sellSharesActivityIndicator.stopAnimating()
                self.showUpdateError()
            } else {
                let quantity = Int(self.sellSharesStepper.value)
                let totalPrice = self.stock.askingPrice * Float(self.sellSharesStepper.value)
                if let ownedShare = self.portfolio.ownedShareForStock(self.stock!) {
                    if quantity > ownedShare.quantity { // attempt to sell too many shares
                        let adjustedPrice = self.stock.askingPrice * Float(ownedShare.quantity)
                        let alert = UIAlertController(title: "Confirm Transaction.", message: "You only own \(ownedShare.quantity) shares of this company. Would you like to sell all of your shares for \(Helpers().formatNumberAsMoney(adjustedPrice))?", preferredStyle: .Alert)
                        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: {(alert: UIAlertAction!) in
                            self.portfolio.sellStock(self.stock!, quantity: ownedShare.quantity, money: adjustedPrice)
                            self.saveContext()
                            self.configureUI()
                        }))
                        self.sellSharesActivityIndicator.stopAnimating()
                        self.presentViewController(alert, animated: true, completion: nil)
                    } else { // number of shares to sell is valid
                        let alert = UIAlertController(title: "Confirm Transaction.", message: "Are you sure you want to sell \(quantity) shares of \(self.stock.company.name). fpr \(Helpers().formatNumberAsMoney(totalPrice))?", preferredStyle: .Alert)
                        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: {(alert: UIAlertAction!) in
                            self.portfolio.sellStock(self.stock!, quantity: quantity, money: totalPrice)
                            self.saveContext()
                            self.configureUI()
                        }))
                        self.sellSharesActivityIndicator.stopAnimating()
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                } else { // no shares are owned
                    let alert = UIAlertController(title: "Transaction Failed", message: "You do not own any shares of \(self.stock.company.name)", preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
                    self.sellSharesActivityIndicator.stopAnimating()
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }
        })
    }
    
    @IBAction func sellSharesStepperValueChanged(sender: UIStepper) {
        let number = Int(sender.value)
        let price = (stock.askingPrice * Float(number))
        sellSharesPriceLabel.text = "\(Int(sender.value)) Share\(Helpers().pluralize(number)) for \(Helpers().formatNumberAsMoney(price))"
    }
    
    /// Configures the view to display the standard values.
    func configureUI() {
        title = stock.company.symbol
        
        companyNameLabel.text = stock.company.name
        symbolLabel.text = stock.company.symbol
        if NSString(string: stock.percentChange).substringToIndex(1) == "-" {
            upDownLabel.text = "▼"
            upDownLabel.textColor = UIColor.redColor()
        } else {
            upDownLabel.text = "▲"
            upDownLabel.textColor = UIColor.greenColor()
        }
        priceLabel.text = "\(Helpers().formatNumberAsMoney(stock.askingPrice)) (\(stock.percentChange))"
        volumeLabel.text = "Volume: \(Helpers().formatNumberWithCommas(stock.volume))"
        if stock.high >= 0.0 && stock.low >= 0.0 {
            highLowLabel.text = "High: \(Helpers().formatNumberAsMoney(stock.high)) Low: \(Helpers().formatNumberAsMoney(stock.low))"
        } else {
            highLowLabel.text = "High: N/A Low: N/A"
        }
        
        dividendYieldLabel.text = "Dividend Yield: \(Helpers().formatNumberAsMoney(stock.dividendYield))"
        if portfolio.hasShares(stock) {
            let quantity = portfolio.ownedShareForStock(stock!)!.quantity
            ownedSharesLabel.text = "Owned: \(Helpers().formatNumberWithCommas(quantity)) Share\(Helpers().pluralize(quantity))"
        } else {
            ownedSharesLabel.text = "Owned: 0 Shares"
        }
        
        if portfolio.investor.watchlist.containsObject(stock!) {
            watchlistButton.setTitle(" Remove from Watchlist ", forState: .Normal)
        } else {
            watchlistButton.setTitle(" Add to Watchlist ", forState: .Normal)
        }
        
        sellSharesPriceLabel.text = "0 Shares for $0.00"
        sellSharesStepper.value = 0.0
        buySharesPriceLabel.text = "0 Shares for $0.00"
        buySharesStepper.value = 0.0
    }
    
    /// Refreshes data for the Stock entity.
    func refreshData() {
        Helpers().cancelDownloadTasks(downloadTasks)
        Helpers().showNetworkActivity()
        downloadTasks.append(Helpers().updateStockData(stock!) {success, error in
            if error != nil {
                Helpers().hideNetworkActivity()
                self.showUpdateError()
            } else {
                // successfully refershed the data, update the UI
                dispatch_async(dispatch_get_main_queue()) {
                    Helpers().hideNetworkActivity()
                    sharedContext.save(nil)
                    self.configureUI()
                }
            }
        })
    }
    
    /// Uses a UIAlertController to inform the user of a failure to refresh the data.
    func showUpdateError() {
        let alert = UIAlertController(title: "Update Failed", message: "Unable to update data for \(stock!.company.symbol)", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    /// Saves the shared context on the main thread.
    func saveContext() {
        dispatch_async(dispatch_get_main_queue()) {
            let error = NSErrorPointer()
            sharedContext.save(error)
            if error != nil {
                println(error)
            }
        }
    }
    
}
