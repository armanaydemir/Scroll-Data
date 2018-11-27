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
    var subtitles: Array<String> = []
    var last_refresh: Date?
    var subFont = UIFont(name: "Times New Roman", size: 12)
    var font = UIFont(name: "Times New Roman", size: 14)
    var link = ""
    @IBOutlet weak var loadIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var table: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        guard let table = self.table, let _ = self.loadIndicator else {
            print("couldn't connect starting vc outlets! bad things coming.....")
            return
        }
        self.navigationItem.title = "Articles"
        table.isHidden = true;
        table.accessibilityIdentifier = "startingTable"
        table.dataSource = self
        table.delegate = self
        table.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        self.fetchData()
        table.register(UINib.init(nibName: "TitleSubtitleTableViewCell", bundle: nil), forCellReuseIdentifier: "default")
        table.rowHeight = UITableViewAutomaticDimension
        
        let systemSubFont = UIFont.preferredFont(forTextStyle: .subheadline)
        let systemFont = UIFont.preferredFont(forTextStyle: .headline)
        
        subFont = UIFont.init(descriptor: subFont!.fontDescriptor.withSymbolicTraits(systemSubFont.fontDescriptor.symbolicTraits)!, size: systemSubFont.pointSize)
        font = UIFont.init(descriptor: font!.fontDescriptor.withSymbolicTraits(systemFont.fontDescriptor.symbolicTraits)!, size: systemFont.pointSize)

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
                        print(self.articles)
                        self.titles = articles.map {$0["title"]} as! Array<String> //be careful, title must be string
                        self.subtitles = articles.map {$0["abstract"]} as! Array<String>
                    } else {
                        throw NSError(domain: "invalid json", code: 1, userInfo: nil)
                    }
                }catch let err{
                    print(data ?? "nil data")
                    print(err)
                    print("invalidddd")
                }
            }else{
                print("server disconnect, gotta do somethin here")
                //self.text[0] = "problem connecting to server";
            }
            
            DispatchQueue.main.async{
                let attributes = [NSFontAttributeName: self.subFont] as [String : Any]
                self.refreshControl.attributedTitle = NSAttributedString(string: (Date().description), attributes: attributes)
                loadIndicator.stopAnimating()
                table.reloadData()
                table.isHidden = false
                self.refreshControl.endRefreshing()
            }
        })
    }
    
    @objc private func refreshData(_ sender: Any) {
        fetchData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.titles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let attributes = [NSFontAttributeName: self.font] as [String : Any]
        let sub_at = [NSFontAttributeName: self.subFont] as [String : Any]
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath)
        if let cell: TitleSubtitleTableViewCell = cell as? TitleSubtitleTableViewCell {
            cell.title.attributedText = NSAttributedString.init(string:  self.titles[indexPath.item], attributes: attributes)
            cell.subtitle.attributedText = NSAttributedString.init(string: self.subtitles[indexPath.item], attributes: sub_at)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            self.link = self.articles[indexPath.item]["article_link"] as! String
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
            destination.articleLink = self.link;
        }
    }
}
