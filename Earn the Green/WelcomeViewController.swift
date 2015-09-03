//
//  WelcomeViewController.swift
//  Earn the Green
//
//  Created by Owen LaRosa on 8/26/15.
//  Copyright (c) 2015 Owen LaRosa. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class WelcomeViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var usernameTextField: UITextField!
    
    @IBOutlet weak var continueButton: UIButton!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        usernameTextField.becomeFirstResponder()
    }
    
    @IBAction func continueButtonTapped(sender: UIButton) {
        processInput()
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        usernameTextField.resignFirstResponder()
        processInput()
        return true
    }
    
    func processInput() {
        // inform the user if the username is invalid
        if count(usernameTextField.text!) > 32 {
            let alert = UIAlertController(title: "Invalid Input", message: "Name can't be longer than 32 characters.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
        } else if count(usernameTextField.text!) == 0 {
            let alert = UIAlertController(title: "Invalid Input", message: "Username cannot be empty.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
        } else { // proceed to configure the game data
            continueButton.enabled = false
            // create Investor entity for the user with "0" identifier
            let userDetails = Investor(identifier: 0, name: usernameTextField.text!, income: 0.0, objective: "Get Rich", context: sharedContext)
            userDetails.portfolio = Portfolio(money: 50000.0, context: sharedContext)
            // show tab bar controller for future app launches
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "AppHasLaunched")
            let dividendDates = GameManager.sharedInstance().getNextDividendDates(NSDate())
            // setup the dividend payment dates
            GameManager.sharedInstance().exDividendDate = dividendDates.exDate
            GameManager.sharedInstance().dividendPayDate = dividendDates.payDate
            sharedContext.save(nil)
            performSegueWithIdentifier("ShowTabBarController", sender: nil)
        }
    }
    
}
