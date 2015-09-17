//
//  MoreViewController.swift
//  Earn the Green
//
//  Created by Owen LaRosa on 8/26/15.
//  Copyright (c) 2015 Owen LaRosa. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class MoreViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
        // About, Source, Reset
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rows = 0
        switch section {
        case 0:
            rows = 2
            // About, How to Play
        case 1:
            rows = 1
            // Change Username
        case 2:
            rows = 1
            // Source Code
        case 3:
            rows = 1
            // Reset
        default:
            break
        }
        return rows
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MoreTableViewCell")!
        
        configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        (view as! UITableViewHeaderFooterView).textLabel!.textColor = UIColor.whiteColor()
    }
    
    func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        (view as! UITableViewHeaderFooterView).textLabel!.textColor = UIColor.whiteColor()
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var header = ""
        switch section {
        case 0:
            header = "About"
        case 1:
            header = "Profile"
        case 2:
            header = "Source"
        case 3:
            header = "Reset"
        default:
            break
        }
        return header
    }
    
    func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        var footer = ""
        switch section {
        case 2:
            footer = "Earn the Green is open-source, meaning that anyone can view and contribute to the project. Tap the link to check out the latest source code on GitHub."
        case 3:
            footer = "Resetting the game will erase all progress including your portfolio and any settings or data. Only do this if you are completely sure you would like to start over."
        default:
            break
        }
        return footer
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            // copyright label
            break
        case (0, 1):
            performSegueWithIdentifier("ShowInstructionView", sender: nil)
            // how to play
            break
        case (1, 0):
            changeUsername()
            break
        case (2, 0):
            UIApplication.sharedApplication().openURL(NSURL(string: "https://github.com/OwenLaRosa/EarnTheGreen")!)
            // link to source code
            break
        case (3, 0):
            resetGame()
            // reset function
            break
        default:
            break
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            cell.textLabel?.text = "Earn the Green 1.0 © 2015"
        case (0, 1):
            cell.textLabel?.text = "How to Play"
        case (1, 0):
            cell.textLabel?.text = "Change Username"
        case (2, 0):
            cell.textLabel?.text = "Source Code"
        case (3, 0):
            cell.textLabel?.text = "Reset Game"
        default:
            break
        }
    }
    
    /// Displays an alert that allows the user to change their username.
    func changeUsername() {
        let dialog = UIAlertController(title: "Change username.", message: "Enter your new username here. Minimum: 1, Maximum: 32 characters.", preferredStyle: .Alert)
        dialog.addTextFieldWithConfigurationHandler({(textField: UITextField) in
            // allow the detection of changes in the text field
            textField.addTarget(self, action: "alertTextFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
        })
        dialog.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        dialog.addAction(UIAlertAction(title: "Ok", style: .Default, handler: {(alertAction: UIAlertAction) in
            let textField: UITextField = dialog.textFields![0] 
            dispatch_async(dispatch_get_main_queue()) {
                GameManager.sharedInstance().user.name = textField.text!
                do {
                    try sharedContext.save()
                } catch _ {
                }
            }
        }))
        // editing changes won't be detected until the user starts typing, so the button should be disabled by default
        (dialog.actions[1] ).enabled = false
        presentViewController(dialog, animated: true, completion: nil)
    }
    
    /// Removes the user's investor entity and resets game progress.
    func resetGame() {
        let confirmation = UIAlertController(title: "Are you sure?", message: "By resetting the game, all progress will be lost forever. Are you sure you would like to continue?", preferredStyle: .Alert)
        confirmation.addAction(UIAlertAction(title: "No thanks", style: .Cancel, handler: nil))
        confirmation.addAction(UIAlertAction(title: "I'm sure", style: .Destructive, handler: {(alert: UIAlertAction) in
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "AppHasLaunched")
            GameManager.sharedInstance().updateStockDataTimer.invalidate()
            sharedContext.deleteObject(GameManager.sharedInstance().user)
            do {
                try sharedContext.save()
            } catch _ {
            }
            let alert = UIAlertController(title: "Progress Reset", message: "Please restart the game to start over.", preferredStyle: .Alert)
            self.presentViewController(alert, animated: true, completion: nil)
        }))
        presentViewController(confirmation, animated: true, completion: nil)
    }
    
    /// Alternative for delegate method in UIAlertView. Referenced from: http://useyourloaf.com/blog/uialertcontroller-changes-in-ios-8.html
    func alertTextFieldDidChange(sender: UITextField) {
        let alertController = self.presentedViewController as! UIAlertController
        let okAction = alertController.actions[1] 
        if sender.text!.characters.count > 0 && sender.text!.characters.count <= 32 {
            okAction.enabled = true
        } else {
            okAction.enabled = false
        }
    }
    
}
