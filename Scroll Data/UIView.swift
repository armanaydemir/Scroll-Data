//
//  UIView.swift
//  Scroll Data
//
//  Created by Deniz Aydemir on 8/26/20.
//  Copyright © 2020 Arman Aydemir. All rights reserved.
//

import UIKit

extension UIView {
    
    struct VerticalStackItem {
        let view: UIView
        let spacingAbove: CGFloat
    }
    
    func createVerticalStack(withViews items: [VerticalStackItem], horizontalMargins: CGFloat) {
        var previousView: UIView?
        items.forEach { item in
            let view = item.view
            self.addSubview(view)
            
            var verticalConstraints: [NSLayoutConstraint] = []
            
            if let previous = previousView {
                verticalConstraints.append(view.topAnchor.constraint(equalTo: previous.bottomAnchor, constant: item.spacingAbove))
            } else {
                verticalConstraints.append(view.topAnchor.constraint(equalToSystemSpacingBelow: self.topAnchor, multiplier: 1))
            }
            
            let horizontalConstraints = [
                view.leadingAnchor.constraint(equalToSystemSpacingAfter: self.leadingAnchor, multiplier: 1),
                view.centerXAnchor.constraint(equalTo: self.centerXAnchor)
            ]
            
            NSLayoutConstraint.activate(verticalConstraints + horizontalConstraints)
            previousView = view
        }
        
        if let lastView = previousView {
            NSLayoutConstraint.activate([ lastView.bottomAnchor.constraint(equalToSystemSpacingBelow: self.bottomAnchor, multiplier: -1)])
        }
    }
}
