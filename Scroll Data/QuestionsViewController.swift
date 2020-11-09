//
//  QuestionsViewController.swift
//  Scroll Data
//
//  Created by Deniz Aydemir on 8/26/20.
//  Copyright © 2020 Arman Aydemir. All rights reserved.
//

import UIKit

class QuestionsViewController: UITableViewController {
    
    var vm: QuestionsViewModel!
    
    var items = [UIView.VerticalStackItem]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //no back button
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        navigationItem.title = "Article Review"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    private func totalSections() -> Int {
        return vm.questions.count + 2
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return totalSections()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 0
        case totalSections() - 1:
            return 1
        default:
            return vm.questions[section - 1].question.options.count
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Please answer the following questions regarding the article."
        case totalSections() - 1:
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
        case totalSections() - 1:
            cell.textLabel?.text = "Submit Answers"
            cell.textLabel?.numberOfLines = 0
            let textColor: UIColor
            if vm.canSubmit() {
                textColor = UIColor.systemBlue
            } else {
                textColor = UIColor.systemGray
            }
            cell.textLabel?.textColor = textColor
            cell.textLabel?.font = UIFont.systemFont(ofSize: 12).withTextStyle(.headline)
            cell.backgroundColor = UIColor.systemBackground
        default:
            let questionVM = vm.questions[indexPath.section - 1]
            let option = questionVM.question.options[indexPath.item]
            
            cell.textLabel?.text = option.text
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.font = UIFont.systemFont(ofSize: 12).withTextStyle(.body)
            
            if questionVM.isOptionSelected(option) {
                cell.backgroundColor = UIColor.systemGray4
            } else {
                cell.backgroundColor = UIColor.systemBackground
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {

        case totalSections() - 1:
            if vm.canSubmit() {
                vm.submitAnswers { success in
                    if success {
                        DispatchQueue.main.async {
                            if let home = (UIApplication.shared.delegate as? AppDelegate)?.homeViewController {
                                self.navigationController?.popToViewController(home, animated: true)
                            } else {
                                self.dismiss(animated: true, completion: nil)
                            }
                        }
                    }
                }
            } else {
                tableView.deselectRow(at: indexPath, animated: false)
            }
        default:
            let questionVM = vm.questions[indexPath.section - 1]
            let option = questionVM.question.options[indexPath.item]
            
            questionVM.selectOption(option)
            tableView.reloadData()
        }
    }
}
