//
//  PortfolioViewController.swift
//  Earn the Green
//
//  Created by Owen LaRosa on 8/10/15.
//  Copyright (c) 2015 Owen LaRosa. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class PortfolioViewController: UIViewController, UITableViewDataSource, UISearchBarDelegate {
    
    var context: NSManagedObjectContext {
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return delegate.managedObjectContext!
    }
    
    var portfolio: Portfolio!
    var shares: [OwnedShare]!
    
    var downloadTasks = [NSURLSessionTask]()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let fetchRequest = NSFetchRequest(entityName: "Portfolio")
        
        // "0" index will be the user's portfolio
        portfolio = (try! sharedContext.executeFetchRequest(fetchRequest))[0] as! Portfolio
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // refresh the data to include any recently added assets
        let fetchRequest = NSFetchRequest(entityName: "OwnedShare")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "portfolio == %@", portfolio)
        shares = (try! sharedContext.executeFetchRequest(fetchRequest)) as! [OwnedShare]
        
        tableView?.reloadData()
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shares.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("AssetTableViewCell")!
        let stock = shares[indexPath.row].stock
        
        configureCell(cell, asset: stock)
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let stock = shares[indexPath.row].stock
        performSegueWithIdentifier("showStockDetailView", sender: stock)
    }
    
    func configureCell(cell: UITableViewCell, asset: Stock) {
        let ownedShare = portfolio.ownedShareForStock(asset)!
        
        cell.textLabel?.text = "\(asset.company.name)"
        cell.detailTextLabel?.text = "Ask: \(Helpers().formatNumberAsMoney(asset.askingPrice)) Owned: \(ownedShare.quantity) Value: \(Helpers().formatNumberAsMoney(asset.askingPrice * Float(ownedShare.quantity)))"
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        Helpers().showNetworkActivity()
        Helpers().cancelDownloadTasks(downloadTasks)
        let searchQuery = searchBar.text!
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.downloadTasks.append(YahooFinance.sharedInstance().getTickerForSearch(searchQuery) {result, error in
                if error != nil {
                    Helpers().hideNetworkActivity()
                    self.showSearchFailedError(searchQuery)
                } else {
                    print(result)
                    let symbol = result!["symbol"] as! String
                    dispatch_async(dispatch_get_main_queue()) {
                        if GameManager.sharedInstance().stockExistsForTicker(symbol) { // Stock entity with this symbol exists
                            
                            searchBar.resignFirstResponder()
                            Helpers().hideNetworkActivity()
                            self.performSegueWithIdentifier("showStockDetailView", sender: GameManager.sharedInstance().getStockForTicker(symbol))
                            //}
                        } else { // entity does not yet exist, attempt to create a new one
                            if result!["type"] as! String == "S" {
                                self.downloadTasks.append(YahooFinance.sharedInstance().getInformationForTicker(symbol) {info, error in
                                    if info!["Ask"] as? NSNull != NSNull() {
                                        dispatch_async(dispatch_get_main_queue()) {
                                            let company = Company(properties: result!, context: sharedContext)
                                            let stock = Stock(properties: info!, context: sharedContext)
                                            company.stock = stock
                                            GameManager.sharedInstance().stocks.append(stock)
                                            
                                            do {
                                                try sharedContext.save()
                                            } catch _ {
                                            }
                                            searchBar.resignFirstResponder()
                                            Helpers().hideNetworkActivity()
                                            self.performSegueWithIdentifier("showStockDetailViewFromSearch", sender: stock)
                                        }
                                    } else {
                                        Helpers().hideNetworkActivity()
                                        self.showSearchFailedError(searchQuery)
                                    }
                                    })
                            } else {
                                Helpers().hideNetworkActivity()
                                self.showSearchFailedError(searchQuery)
                            }
                        }
                    }
                }
                })
        }
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        Helpers().cancelDownloadTasks(downloadTasks)
        Helpers().hideNetworkActivity()
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showStockDetailView" {
            let destination = segue.destinationViewController as! StockDetailViewController
            destination.stock = sender as! Stock
            destination.portfolio = portfolio
            destination.shouldRefresh = true // data may be out of date
        } else if segue.identifier == "showStockDetailViewFromSearch" {
            // data has just been downloaded and is up to date
            let destination = segue.destinationViewController as! StockDetailViewController
            destination.stock = sender as! Stock
            destination.portfolio = portfolio
        }
    }
    
    /// Uses a UIAlertController to inform the user that the search failed.
    func showSearchFailedError(query: String) {
        dispatch_async(dispatch_get_main_queue()) {
            let alert = UIAlertController(title: "Search Failed", message: "Could not find match for search: \"\(query)\".", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
}
