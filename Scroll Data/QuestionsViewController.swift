//
//  QuestionsViewController.swift
//  Scroll Data
//
//  Created by Deniz Aydemir on 8/26/20.
//  Copyright © 2020 Arman Aydemir. All rights reserved.
//

import UIKit

class QuestionsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let questions = Array(0..<10).map { Question(question: "\($0) What is going on?", options: ["My one and only", "mmmmmm paosidfu apsodif uapsodifu apsodif uaspifap oisuad fpasoi ufm", "yes", "good"])}
            
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
        
        let titleViews = createTitleViews(withTitle: "Review", subtitle: "Please answer the following questions regarding the reading.")
        
        let allViews: [UIView.VerticalStackItem] = titleViews + questions.map { UIView.VerticalStackItem(view: $0.createView(), spacingAbove: 64) }
        
        scrollView.createVerticalStack(withViews: allViews, horizontalMargins: 0)
        
        
    }
    
    private func createTitleViews(withTitle title: String, subtitle: String) -> [UIView.VerticalStackItem] {
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 12).withTextStyle(.title1)
        titleLabel.numberOfLines = 0
        
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 12).withTextStyle(.title3)
        subtitleLabel.numberOfLines = 0
        
        return [UIView.VerticalStackItem(view: titleLabel, spacingAbove: 0), UIView.VerticalStackItem(view: subtitleLabel, spacingAbove: 4)]
    }
}
