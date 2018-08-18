//
//  StartingViewController.swift
//  Scroll Data
//
//  Created by Aydemir on 8/18/18.
//  Copyright © 2018 Arman Aydemir. All rights reserved.
//

import UIKit

class StartingViewController: UIViewController {
    @IBOutlet weak var articleLink: UITextField!
    @IBOutlet weak var loadIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var articles: UITableView!
    @IBOutlet weak var startButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.articleLink.text = "https://www.nytimes.com/2018/08/13/world/europe/erdogan-turkey-lira-crisis.html"
        //self.startButton.setTitle("Tap tp Start Reading", for: UIControlState.normal)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func startReading(_ sender: Any) {
        self.performSegue(withIdentifier: "startReading", sender: sender)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        let vc = segue.destination
//        if let destination:ArticleViewController = vc as? ArticleViewController {
//            destination.articleLink = self.articleLink.text;
//        }
//    }
    

}
