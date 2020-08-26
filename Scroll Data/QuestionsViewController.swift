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
            
//        let scrollView = UIScrollView()
//        scrollView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(scrollView)
//        NSLayoutConstraint.activate([
//            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
//            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
//            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
//        ])
        
//        let titleViews = createTitleViews(withTitle: "Review", subtitle: "Please answer the following questions regarding the reading.")
        
//        let allViews: [UIView.VerticalStackItem] = titleViews + vm.questions.map { $0.question }.map { UIView.VerticalStackItem(view: $0.createView(), spacingAbove: 64) }
        
//        scrollView.createVerticalStack(withViews: allViews, horizontalMargins: 0)
        
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return vm.questions.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return vm.questions[section].question.options.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return vm.questions[section].question.text
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 64
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let questionVM = vm.questions[indexPath.section]
        let option = questionVM.question.options[indexPath.item]
        cell.textLabel?.text = option.text
        cell.textLabel?.numberOfLines = 0
        cell.setSelected(questionVM.isOptionSelected(option), animated: true)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let questionVM = vm.questions[indexPath.section]
        let option = questionVM.question.options[indexPath.item]
        
        questionVM.selectOption(option)
        tableView.reloadData()
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
    
    func optionTapped(_ option: Question.Option) {
//        selectOption(option)
    }
}
