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
        
        let stack = UIStackView(arrangedSubviews: [questionLabel] + optionViews)
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .leading
        stack.setCustomSpacing(32, after: questionLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }
    
    private func createOptionView(withText text: String) -> UIView {
        let button = UIButton(type: .custom)
        button.isHighlighted = false
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.numberOfLines = 0
        button.setTitle(text, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12).withTextStyle(.subheadline)
        
        let textColor = UIColor.black
        button.setTitleColor(textColor, for: .normal)
        button.setTitleColor(textColor.withAlphaComponent(0.5), for: .highlighted)
        
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        return button
    }
}
