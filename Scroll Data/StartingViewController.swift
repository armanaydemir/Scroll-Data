//
//  StartingViewController.swift
//  Scroll Data
//
//  Created by Aydemir on 8/18/18.
//  Copyright © 2018 Arman Aydemir. All rights reserved.
//

import UIKit

class StartingViewController: UIViewController {
    var articles: Array<Any> = []
    var titles: Array<String> = []
    @IBOutlet weak var articleLink: UITextField!
    @IBOutlet weak var loadIndicator: UIActivityIndicatorView!
    

    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var startButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.articleLink.text = "https://www.nytimes.com/2018/08/13/world/europe/erdogan-turkey-lira-crisis.html"
        self.startButton.setTitle("Tap tp Start Reading", for: UIControlState.normal)
        // Do any additional setup after loading the view.
        guard let table = self.table, let loadIndicator = self.loadIndicator, let startButton = self.startButton, let articleLink = self.articleLink else {
            print("couldn't connect starting vc outlets! bad things coming.....")
            return
        }
        table.isHidden = true;
        loadIndicator.hidesWhenStopped = true
        loadIndicator.startAnimating()
        
        Networking.request(headers:nil, method: "GET", fullEndpoint: "http://159.203.207.54:22364/articles", body: nil, completion: { data, response, error in
            if let dataExists = data, error == nil {
                do {
                    if let articles = try JSONSerialization.jsonObject(with: dataExists, options: .allowFragments) as? Array<Any> {
                        print(articles)
                    
                    } else {
                        throw NSError(domain: "invalid json", code: 1, userInfo: nil)
                    }
                }catch let err{
                    print("invalidddd")
                }
            }else{
                print("server disconnect, gotta do somethin here")
                //self.text[0] = "problem connecting to server";
            }
            
            DispatchQueue.main.async{
                loadIndicator.stopAnimating()
                table.reloadData()
                
                
            }
        })
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
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination
        if let destination:ArticleViewController = vc as? ArticleViewController {
            destination.articleLink = self.articleLink.text;
        }
    }
    

}
