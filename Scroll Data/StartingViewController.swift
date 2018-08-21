//
//  StartingViewController.swift
//  Scroll Data
//
//  Created by Aydemir on 8/18/18.
//  Copyright © 2018 Arman Aydemir. All rights reserved.
//

import UIKit

class StartingViewController: UIViewController,UITableViewDataSource, UITableViewDelegate {
    var articles: Array<[String : String]> = []
    var titles: Array<String> = []
    let font: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
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
                    if let articles = try JSONSerialization.jsonObject(with: dataExists, options: .allowFragments) as? Array<[String : String]> {
                        self.articles = articles
                        self.titles = articles.map {$0["title"]!}
                        print(self.articles)
                        print(self.titles)
                        
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
                table.isHidden = false
                
            }
        })
        table.dataSource = self
        table.delegate = self
        table.register(UINib.init(nibName: "TextCell", bundle: nil), forCellReuseIdentifier: "default")
        table.rowHeight = UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.articles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let aString = self.titles[indexPath.item]
        let attributes = [NSFontAttributeName: font] as [String : Any]
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath)
        if let cell: TextCell = cell as? TextCell {
            cell.textSection.attributedText = NSAttributedString.init(string: aString, attributes: attributes)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.articleLink.text = self.articles[indexPath.item]["article_link"]
        self.performSegue(withIdentifier: "startReading", sender: self)
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
