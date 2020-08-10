//
//  TitleSubtitleTableViewCell.swift
//  Scroll Data
//
//  Created by Deniz Aydemir on 9/25/18.
//  Copyright © 2018 Arman Aydemir. All rights reserved.
//

import UIKit

class TitleSubtitleTableViewCell: UITableViewCell {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subtitle: UILabel!
    @IBOutlet weak var lines: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
