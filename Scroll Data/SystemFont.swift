//
//  SystemFont.swift
//  Scroll Data
//
//  Created by Aydemir on 11/26/18.
//  Copyright © 2018 Arman Aydemir. All rights reserved.
//

import UIKit

extension UIFont {
    
    func withTextStyle(_ textStyle: UIFont.TextStyle) -> UIFont? {
        let style = UIFont.preferredFont(forTextStyle: textStyle)
        guard let des = self.fontDescriptor.withSymbolicTraits(style.fontDescriptor.symbolicTraits) else { return nil }
        return UIFont.init(descriptor: des, size: style.pointSize)
    }
}
