//
//  QuestionView.swift
//  Scroll Data
//
//  Created by Deniz Aydemir on 8/26/20.
//  Copyright © 2020 Arman Aydemir. All rights reserved.
//

import UIKit

struct Question {
    
    let question: String
    let options: [String]

    func createView() -> UIView {
        let questionLabel = UILabel()
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        questionLabel.numberOfLines = 0
        questionLabel.text = question
        questionLabel.font = UIFont.systemFont(ofSize: 12).withTextStyle(.headline)
        
        
        let optionViews = options.map { self.createOptionView(withText: $0) }
        
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.createVerticalStack(withViews: [UIView.VerticalStackItem(view: questionLabel, spacingAbove: 0)] + optionViews, horizontalMargins: 0)
        return view
    }
    
    private func createOptionView(withText text: String) -> UIView.VerticalStackItem {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.text = text
        label.font = UIFont.systemFont(ofSize: 12).withTextStyle(.subheadline)
        NSLayoutConstraint.activate([
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        return UIView.VerticalStackItem(view: label, spacingAbove: 4)
    }
}
