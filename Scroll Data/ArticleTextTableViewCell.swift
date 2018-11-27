//
//  ArticleTextTableViewCell.swift
//  Scroll Data
//
//  Created by Aydemir on 11/26/18.
//  Copyright © 2018 Arman Aydemir. All rights reserved.
//

import UIKit

class ArticleTextTableViewCell: UITableViewCell {

    @IBOutlet weak var widthSpacing: NSLayoutConstraint!
    @IBOutlet weak var topSpacing: NSLayoutConstraint!
    @IBOutlet weak var textSection: UILabel!
    
    
    public static let widthSpacingConstant: CGFloat = 16.0
    public static let topSpacingConstant: CGFloat = 4.0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        widthSpacing.constant = ArticleTextTableViewCell.widthSpacingConstant
        topSpacing.constant = ArticleTextTableViewCell.topSpacingConstant
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(false, animated: animated)
        
        // Configure the view for the selected state
    }
}
