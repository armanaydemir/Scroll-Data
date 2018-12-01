//
//  SubmitTableViewCell.swift
//  Scroll Data
//
//  Created by Aydemir on 11/26/18.
//  Copyright © 2018 Arman Aydemir. All rights reserved.
//

import UIKit

class SubmitTableViewCell: UITableViewCell {
    @IBOutlet weak var submitButton: UIButton!
    
    weak var delegate: SubmitTableViewCellDelegate?
    override func awakeFromNib() {
        super.awakeFromNib()
        submitButton.layer.cornerRadius = 4.0
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func submitData(_ sender: Any) {
        self.delegate?.submitData()
    }
    
    
}

protocol SubmitTableViewCellDelegate: NSObjectProtocol {
    func submitData()
}
