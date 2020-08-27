//
//  QuestionsViewController.swift
//  Scroll Data
//
//  Created by Deniz Aydemir on 8/26/20.
//  Copyright © 2020 Arman Aydemir. All rights reserved.
//

import UIKit

class QuestionsViewController: UITableViewController {
    
    let vm = QuestionsViewModel()
    
    var items = [UIView.VerticalStackItem]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return vm.questions.count + 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 0
        case vm.questions.count + 1:
            return 1
        default:
            return vm.questions[section - 1].question.options.count
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Please answer the following questions regarding the article."
        case vm.questions.count + 1:
            return nil
        default:
            return vm.questions[section - 1].question.text
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 64
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        switch indexPath.section {
        case 1..<vm.questions.count + 1:
            let questionVM = vm.questions[indexPath.section - 1]
            let option = questionVM.question.options[indexPath.item]
            
            cell.textLabel?.text = option.text
            cell.textLabel?.textColor = UIColor.darkText
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.font = UIFont.systemFont(ofSize: 12).withTextStyle(.body)
            
            if questionVM.isOptionSelected(option) {
                cell.backgroundColor = UIColor.systemGray4
            } else {
                cell.backgroundColor = UIColor.systemBackground
            }
            
        default:
            cell.textLabel?.text = "Submit Answers"
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.textColor = UIColor.systemBlue
            cell.textLabel?.font = UIFont.systemFont(ofSize: 12).withTextStyle(.headline)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0..<vm.questions.count + 1:
            let questionVM = vm.questions[indexPath.section - 1]
            let option = questionVM.question.options[indexPath.item]
            
            questionVM.selectOption(option)
            tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none)
        default:
            print("submit answers")
        }
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



extension QuestionViewModel {
    func createView() -> UIView {
        let questionLabel = UILabel()
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        questionLabel.numberOfLines = 0
        questionLabel.text = question.text
        questionLabel.font = UIFont.systemFont(ofSize: 12).withTextStyle(.headline)
        
        
        let optionViews = question.options.map { self.createOptionView(withText: $0.text) }
        
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
