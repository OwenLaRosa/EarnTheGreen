//
//  WatchlistViewController.swift
//  Earn the Green
//
//  Created by Owen LaRosa on 8/25/15.
//  Copyright (c) 2015 Owen LaRosa. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class WatchlistViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var watchlist = [Stock]()
    var user: Investor!
    
    // MARK: - view life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let fetchRequest = NSFetchRequest(entityName: "Investor")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "identifier", ascending: true)]
        
        user = (try! sharedContext.executeFetchRequest(fetchRequest))[0] as! Investor
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        watchlist = user.watchlist.array as! [Stock]
        
        tableView.reloadData()
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return watchlist.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("WatchlistTableViewCell")!
        
        configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let stock = watchlist[indexPath.row]
        performSegueWithIdentifier("showStockDetailView", sender: stock)
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        cell.textLabel?.text = watchlist[indexPath.row].company.name
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle {
        case .Delete:
            watchlist.removeAtIndex(indexPath.row)
            user.watchlist = NSOrderedSet(array: watchlist)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        default:
            return
        }
        saveContext()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showStockDetailView" {
            let destination = segue.destinationViewController as! StockDetailViewController
            destination.portfolio = user.portfolio
            destination.stock = sender as! Stock
            destination.shouldRefresh = true
        }
    }
    
    func saveContext() {
        dispatch_async(dispatch_get_main_queue()) {
            do {
                try sharedContext.save()
            } catch {
                
            }
        }
    }
    
}
