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

        let questions = Array(0..<10).map { Question(question: "\($0) What is going on?", options: ["My one and only", "mmmmmmm", "yes", "good"])}
            
        
        
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
        
        var previousQuestionView: UIView?
        questions.forEach { question in
            let questionView = question.createView()
            scrollView.addSubview(questionView)
            
            var verticalConstraints: [NSLayoutConstraint] = []
            
            if let previous = previousQuestionView {
                verticalConstraints.append(questionView.topAnchor.constraint(equalTo: previous.bottomAnchor, constant: 64))
            } else {
                verticalConstraints.append(questionView.topAnchor.constraint(equalToSystemSpacingBelow: scrollView.topAnchor, multiplier: 1))
            }
            
            let horizontalConstraints = [
                questionView.leadingAnchor.constraint(equalToSystemSpacingAfter: scrollView.leadingAnchor, multiplier: 1),
                questionView.trailingAnchor.constraint(equalToSystemSpacingAfter: scrollView.trailingAnchor, multiplier: 1)
            ]
            
            NSLayoutConstraint.activate(verticalConstraints + horizontalConstraints)
            previousQuestionView = questionView
        }
        
        if let lastView = previousQuestionView {
            NSLayoutConstraint.activate([ lastView.bottomAnchor.constraint(equalToSystemSpacingBelow: scrollView.bottomAnchor, multiplier: 1)])
        }
        
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
