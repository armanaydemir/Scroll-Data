//
//  IntroViewController.swift
//  Scroll Data
//
//  Created by Deniz Aydemir on 8/28/20.
//  Copyright © 2020 Arman Aydemir. All rights reserved.
//

import UIKit
import WebKit

class IntroViewController: UIViewController {

    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var agreeButton: UIButton!
    @IBOutlet weak var agreeLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    let userInfo = UserInfo.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Human Research Study"
        
        scrollView.isHidden = true
        agreeButton.isEnabled = false
        
        if userInfo.agreedToTerms {
            showArticles()
        } else {
            spinner.startAnimating()
            userInfo.fetchSettings { settings in
                DispatchQueue.main.async {
                    self.spinner.stopAnimating()
                    self.webView.loadHTMLString(settings.introHTML, baseURL: nil)
                    self.scrollView.isHidden = false
                }
            }
        }

        
        let adjustToKeyboard: (Notification) -> Void = { notification in
            guard let value = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
            
            let keyboardScreenEndFrame = value.cgRectValue
            let keyboardViewEndFrame = self.view.convert(keyboardScreenEndFrame, from: self.view.window)

            let newInsets: UIEdgeInsets
            if notification.name == UIResponder.keyboardWillHideNotification {
                newInsets = .zero
            } else {
                newInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - self.view.safeAreaInsets.bottom, right: 0)
            }
            
            self.scrollView.contentInset = newInsets
            self.scrollView.scrollIndicatorInsets = newInsets
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil, using: adjustToKeyboard)
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil, using: adjustToKeyboard)
        
        emailTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        emailTextField.addTarget(self, action: #selector(textFieldEditingDidEnd), for: .editingDidEnd)
        emailTextField.addTarget(self, action: #selector(textFieldActionTriggered), for: .primaryActionTriggered)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func showArticles() {
        performSegue(withIdentifier: "start", sender: self)
    }
    
    @IBAction func agreeTapped(_ sender: Any) {
        userInfo.agreedToTerms = true
        
        let email = emailTextField.text ?? ""
        userInfo.email = email
        Server.Request.submitEmail(email: email).startRequest { (result : Result<GenericResponse, Swift.Error>) in print(result) }
        
        showArticles()
    }
    
    @objc private func textFieldActionTriggered() {
        emailTextField.endEditing(true)
    }
    
    @objc private func textFieldChanged() {
        agreeButton.isEnabled = textFieldTextIsValidEmail()
        if emailTextField.textColor != UIColor.darkText && textFieldTextIsValidEmail() {
            emailTextField.textColor = UIColor.darkText
        }
    }
    
    @objc private func textFieldEditingDidEnd() {
        if !textFieldTextIsValidEmail() {
            emailTextField.textColor = UIColor.systemRed
        } else {
            emailTextField.textColor = UIColor.darkText

        }
    }
    
    private func textFieldTextIsValidEmail() -> Bool {
        return emailTextField.text?.isValidEmail() ?? false
    }

}


extension String {
    func isValidEmail() -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: self)
    }
}
