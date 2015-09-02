//
//  StockTableViewCell.swift
//  Earn the Green
//
//  Created by Owen LaRosa on 8/17/15.
//  Copyright (c) 2015 Owen LaRosa. All rights reserved.
//

import Foundation
import UIKit

class StockTableViewCell: UITableViewCell {
    
    let selectedColor = UIColor(red: 0.6, green: 1.0, blue: 0.2, alpha: 1.0)
    let unselectedColor = UIColor(red: 0.5, green: 0.8, blue: 0.3, alpha: 1.0)
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if selected {
            backgroundColor = selectedColor
        } else {
            backgroundColor = unselectedColor
        }
    }
    
}
