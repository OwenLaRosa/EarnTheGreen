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
        
        user = sharedContext.executeFetchRequest(fetchRequest, error: nil)![0] as! Investor
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
        let cell = tableView.dequeueReusableCellWithIdentifier("WatchlistTableViewCell") as! UITableViewCell
        
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showStockDetailView" {
            let destination = segue.destinationViewController as! StockDetailViewController
            destination.portfolio = user.portfolio
            destination.stock = sender as! Stock
            destination.shouldRefresh = true
        }
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    /*lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Stock")
        
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "investor == %@", self.user);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
        }()
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            
        case .Delete:
            tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
        
        dispatch_async(dispatch_get_main_queue()) {
            sharedContext.save(nil)
        }
    }*/
    
}
