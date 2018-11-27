//
//  TitleCellTableViewCell.swift
//  Scroll Data
//
//  Created by Aydemir on 6/20/18.
//  Copyright © 2018 Arman Aydemir. All rights reserved.
//

import UIKit

class TitleCellTableViewCell: UITableViewCell {
    @IBOutlet weak var titleText: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(false, animated: animated)

        // Configure the view for the selected state
    }
    
}
