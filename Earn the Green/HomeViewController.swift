//
//  HomeViewController.swift
//  Earn the Green
//
//  Created by Owen LaRosa on 8/25/15.
//  Copyright (c) 2015 Owen LaRosa. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class HomeViewController: UIViewController, UITableViewDataSource {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var topView: UIView!
    
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var netWorthLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    var user: Investor!
    
    var investorStats = [(String, String)]()
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let fetchRequest = NSFetchRequest(entityName: "Investor")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "identifier", ascending: true)]
        
        // first result will be the user's entity
        self.user = (try! sharedContext.executeFetchRequest(fetchRequest))[0] as! Investor
        
        // begin background refreshing of stock data
        GameManager.sharedInstance().startStockDataTimer()
        
        // check for and pay and dividends since last session
        GameManager.sharedInstance().processDividends(user.portfolio)
        
        // configure the UI and statistics
        usernameLabel.text = user.name
        netWorthLabel.text = Helpers().formatNumberAsMoney(user.netWorth)
        
        investorStats = [
            ("Stats:", ""),
            ("", ""),
            ("Cash", "\(Helpers().formatNumberAsMoney(user.valueOfCash))"),
            ("Percent Cash", "\(Helpers().formatNumberAsPercentage(user.valueOfCash / user.netWorth))"),
            ("Stocks", "\(Helpers().formatNumberAsMoney(user.valueOfStocks))"),
            ("Percent Stocks", "\(Helpers().formatNumberAsPercentage(user.valueOfStocks / user.netWorth))"),
            ("Shares Owned", "\(user.numberOfShares)"),
            ("Companies", "\(user.numberOfDifferentAssets)"),
            ("Total Trades", "\(Helpers().formatNumberWithCommas(user.trades))"),
            ("", ""),
            ("Quick Look", ""),
            ("", "")
        ]
        
        let topShares = fetchTopOwnedShares()
        if topShares.count > 0 {
            print(topShares.count)
            for i in topShares {
                investorStats.append(("\(i.stock.company.symbol) (\(Helpers().formatNumberWithCommas(i.quantity)))", "\(Helpers().formatNumberAsMoney(i.stock.askingPrice))"))
            }
        } else {
            investorStats.append(("You don't own any shares yet.", ""))
        }
        
        investorStats.append(("", ""))
        
        tableView.reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.frame.size.height = tableView.contentSize.height
        
        let width = UIScreen.mainScreen().bounds.width
        let height = topView.frame.height + tableView.frame.height + 24
        scrollView.contentSize = CGSizeMake(width, height)
    }
    
    @IBAction func managePortfolioButtonTapped(sender: UIButton) {
        // switch tab to the portfolio view
        tabBarController?.selectedIndex = 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return investorStats.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("InvestorStatCell")!
        configureCell(cell, indexPath: indexPath)
        
        return cell
    }
    
    func configureCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        let index = indexPath.row
        // assign text to the primary and detail labels
        cell.textLabel?.text = investorStats[index].0
        cell.detailTextLabel?.text = investorStats[index].1
        // reduce row height if not occupied: not yet functioning
        if investorStats[index].0 == "" && investorStats[index].1 == "" {
            let cellHeight = floor(cell.frame.height / 2)
            cell.bounds.size.height = cellHeight
        }
    }
    
    /// Returns an array of the top 5 OwnedShare entities in which the user owns the most individual shares.
    func fetchTopOwnedShares() -> [OwnedShare] {
        let fetchRequest = NSFetchRequest(entityName: "OwnedShare")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "quantity", ascending: false)]
        fetchRequest.fetchLimit = 5
        let results = (try! sharedContext.executeFetchRequest(fetchRequest)) as! [OwnedShare]
        return results
    }
    
}
