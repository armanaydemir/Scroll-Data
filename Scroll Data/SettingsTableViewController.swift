//
//  SettingsTableViewController.swift
//  Scroll Data
//
//  Created by Deniz Aydemir on 8/29/20.
//  Copyright © 2020 Arman Aydemir. All rights reserved.
//

import UIKit
import MessageUI

class SettingsTableViewController: UITableViewController {
    
    enum Option: Int, CaseIterable {
        case viewTerms = 0
//        case contact = 1
        
        func label() -> String {
            switch self {
            case .viewTerms:
                return "View Terms"
//            case .contact:
//                return "Contact Us"
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Option.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        let cellOption = Option(rawValue: indexPath.section)
        cell.textLabel?.text = cellOption?.label()

        return cell
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellOption = Option(rawValue: indexPath.section)
        switch cellOption {
        case .viewTerms:
            performSegue(withIdentifier: "terms", sender: self)
//        case .contact:
//            let emailTitle = "Reader Research Inquiry"
//            let to = ["arman.aydemir@colorado.edu"]
//            let mailComposer = MFMailComposeViewController()
//            mailComposer.mailComposeDelegate = self
//            mailComposer.setSubject(emailTitle)
//            mailComposer.setToRecipients(to)
//            self.present(mailComposer, animated: true, completion: nil)
        case .none:
            break
        }
    }

}


extension SettingsTableViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true, completion: nil)
    }
}
