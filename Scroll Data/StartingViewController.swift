//
//  StartingViewController.swift
//  Scroll Data
//
//  Created by Aydemir on 8/18/18.
//  Copyright © 2018 Arman Aydemir. All rights reserved.
//

import UIKit

class StartingViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let refreshControl = UIRefreshControl()
    var articles: Array<[String : Any]> = []
    var titles: Array<String> = []
    var last_refresh: Date?
    let font: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
    var link = ""
    @IBOutlet weak var loadIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var table: UITableView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        guard let table = self.table, let loadIndicator = self.loadIndicator else {
            print("couldn't connect starting vc outlets! bad things coming.....")
            return
        }
        table.isHidden = true;
        loadIndicator.hidesWhenStopped = true
        loadIndicator.startAnimating()
        
        Networking.request(headers:nil, method: "GET", fullEndpoint: "http://159.203.207.54:22364/articles", body: nil, completion: { data, response, error in
            if let dataExists = data, error == nil {
                do {
                    if let articles = try JSONSerialization.jsonObject(with: dataExists, options: .allowFragments) as? Array<[String : Any]> {
                        self.articles = articles
                        self.titles = articles.map {$0["title"]!} as! Array<String> //be careful, title must be string
                        //print(self.articles)
                        
                        self.titles.insert("go to your pasteboard", at: 0)
                        //print(self.titles)
                    } else {
                        throw NSError(domain: "invalid json", code: 1, userInfo: nil)
                    }
                }catch let err{
                    print(data)
                    print("invalidddd")
                }
            }else{
                self.titles = ["go to your pasteboard"]
                print("server disconnect, gotta do somethin here")
                //self.text[0] = "problem connecting to server";
            }
            
            DispatchQueue.main.async{
                self.last_refresh = Date()
                loadIndicator.stopAnimating()
                table.reloadData()
                table.isHidden = false
                
            }
        })
        table.dataSource = self
        table.delegate = self
        table.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        
        table.register(UINib.init(nibName: "TextCell", bundle: nil), forCellReuseIdentifier: "default")
        table.rowHeight = UITableViewAutomaticDimension
    }
    private func fetchData() {
        guard let table = self.table, let loadIndicator = self.loadIndicator else {
            print("couldn't connect starting vc outlets! bad things coming.....")
            return
        }
        loadIndicator.startAnimating()
        Networking.request(headers:nil, method: "GET", fullEndpoint: "http://159.203.207.54:22364/articles", body: nil, completion: { data, response, error in
            if let dataExists = data, error == nil {
                do {
                    if let articles = try JSONSerialization.jsonObject(with: dataExists, options: .allowFragments) as? Array<[String : Any]> {
                        self.articles = articles
                        self.titles = articles.map {$0["title"]!} as! Array<String> //be careful, title must be string
                        //print(self.articles)
                        
                        self.titles.insert("go to your pasteboard", at: 0)
                        //print(self.titles)
                    } else {
                        throw NSError(domain: "invalid json", code: 1, userInfo: nil)
                    }
                }catch let err{
                    print(data)
                    print("invalidddd")
                }
            }else{
                self.titles = ["go to your pasteboard"]
                print("server disconnect, gotta do somethin here")
                //self.text[0] = "problem connecting to server";
            }
            
            DispatchQueue.main.async{
                let attributes = [NSFontAttributeName: self.font] as [String : Any]
                self.refreshControl.attributedTitle = NSAttributedString(string: Date().description, attributes: attributes)
                loadIndicator.stopAnimating()
                table.reloadData()
                table.isHidden = false
                self.refreshControl.endRefreshing()
            }
        })
    }
    
    @objc private func refreshData(_ sender: Any) {
        // Fetch Weather Data
        fetchData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.titles.count
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
        
        if(indexPath.item == 0){
            if let link = UIPasteboard.general.string {
                print(link)
                self.link = link
                self.performSegue(withIdentifier: "startReading", sender: self)
            }
        }else{
            self.link = self.articles[indexPath.item - 1]["article_link"] as! String
            self.performSegue(withIdentifier: "startReading", sender: self)
        }
        
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
            destination.articleLink = self.link;
        }
    }
    

}
