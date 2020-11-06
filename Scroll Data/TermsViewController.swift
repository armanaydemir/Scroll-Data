//
//  TermsViewController.swift
//  Scroll Data
//
//  Created by Deniz Aydemir on 8/29/20.
//  Copyright © 2020 Arman Aydemir. All rights reserved.
//

import UIKit
import WebKit

class TermsViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserInfo.shared.fetchSettings { settings in
            self.webView.loadHTMLString(settings.introHTML, baseURL: nil)
        }
    }
}
