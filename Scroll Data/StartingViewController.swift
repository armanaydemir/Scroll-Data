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
    let subFont = SystemFont.init(fontName: "Times New Roman")?.getFont(withTextStyle: .subheadline) ?? UIFont.preferredFont(forTextStyle: .subheadline)
    let headFont = SystemFont.init(fontName: "Times New Roman")?.getFont(withTextStyle: .headline) ?? UIFont.preferredFont(forTextStyle: .headline)
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
        table.rowHeight = UITableView.automaticDimension
    }
    private func fetchData() {
        guard let table = self.table, let loadIndicator = self.loadIndicator else {
            print("couldn't connect starting vc outlets! bad things coming.....")
            return
        }
        loadIndicator.startAnimating() //POST 
        Networking.request(headers:nil, method: "GET", fullEndpoint: serverURL+"/sessions", body: ["UDID":"FCD0FA4A_26EF_4B21_85F8_EADFB8871559"], completion: { data, response, error in
            if let dataExists = data, error == nil {
                do {
                    if let articles = try JSONSerialization.jsonObject(with: dataExists, options: .allowFragments) as? Array<[String : Any]> {
                        self.articles = articles
                        //print(articles)
                        self.titles = articles.map {
                            if let title = $0["article_title"] as? String {
                                return title
                            } else {
                                print("title incorrect format")
                                return ""
                            }
                        } //be careful, title must be string
                        self.subtitles = articles.map {
                            if let title = $0["type"] as? String, let version =  $0["version"] as? String {
                                return title + "    " + version
                            } else {
                                print("abstract incorrect format")
                                return ""
                            }
                        }
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
                let attributes = [NSAttributedString.Key.font: self.subFont]
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
        let attributes = [NSAttributedString.Key.font: self.headFont]
        let sub_at = [NSAttributedString.Key.font: self.subFont]
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath)
        if let cell: TitleSubtitleTableViewCell = cell as? TitleSubtitleTableViewCell {
            cell.title.attributedText = NSAttributedString.init(string:  self.titles[indexPath.item], attributes: attributes)
            cell.subtitle.attributedText = NSAttributedString.init(string: self.subtitles[indexPath.item], attributes: sub_at)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            self.link = self.articles[indexPath.item]["_id"] as! String
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
        if let destination: ArticleViewController = vc as? ArticleViewController {
            destination.mode = .replay(viewModel: SessionReplayViewModel(articleLink: self.link))
            guard let a = UIApplication.shared.delegate as? AppDelegate else {return}
            a.autoRotate = false
            a.orientation = UIDevice.current.orientation
        }
    }
}
