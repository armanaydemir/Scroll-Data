//
//  StartingViewController.swift
//  Scroll Data
//
//  Created by Aydemir on 8/18/18.
//  Copyright © 2018 Arman Aydemir. All rights reserved.
//

import UIKit

class StartingViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    enum TableMode: Int {
        case articles = 0
        case sessions = 1
    }
    
    private var tableMode: TableMode = .articles {
        didSet {
            switch tableMode {
            case .articles:
                if articles.count > 0 {
                    table.reloadData()
                } else {
                    fetchData()
                }
            case .sessions:
                if sessions.count > 0 {
                    table.reloadData()
                } else {
                    fetchSessions()
                }
            }
        }
    }
    
    private let refreshControl = UIRefreshControl()
    
    var articles: [ArticleBlurb] = []
    var sessions: [Session] = []
    
    var last_refresh: Date?
    
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
        
        let segmentedControl = UISegmentedControl.init(items: ["Articles", "Sessions"])
        segmentedControl.selectedSegmentIndex = self.tableMode.rawValue
        segmentedControl.addTarget(self, action: #selector(switchedTable(segmentedControl:)), for: .valueChanged)
        navigationItem.titleView = segmentedControl
        
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
    
    @objc private func switchedTable(segmentedControl: UISegmentedControl) {
        switch segmentedControl.selectedSegmentIndex {
        case TableMode.articles.rawValue:
            self.tableMode = .articles
        case TableMode.sessions.rawValue:
            self.tableMode = .sessions
        default:
            break
        }
    }
    
    private func fetchSessions() {
        guard let table = self.table, let loadIndicator = self.loadIndicator else {
             print("couldn't connect starting vc outlets! bad things coming.....")
             return
         }
         loadIndicator.startAnimating() //POST
         Networking.request(headers:nil, method: "GET", fullEndpoint: serverURL+"/sessions", body: nil, completion: { data, response, error in
             if let dataExists = data, error == nil {
                 do {
                     guard let list = try JSONSerialization.jsonObject(with: dataExists, options: .allowFragments) as? [Any]
                         else { throw NSError(domain: "invalid json", code: 1, userInfo: nil) }
                     print("sessions: \(list)")
//                     self.sessions = list.compactMap({ try? Session(data: $0) })
                 } catch let err {
                     print(data ?? "nil data")
                     print(err)
                     print("invalidddd")
                 }
             }else{
                 print("server disconnect, gotta do somethin here")
                 //self.text[0] = "problem connecting to server";
             }
             
             DispatchQueue.main.async{
                 let attributes = [NSAttributedString.Key.font: baseFont.withTextStyle(.subheadline)!]
                 self.refreshControl.attributedTitle = NSAttributedString(string: (Date().description), attributes: attributes)
                 loadIndicator.stopAnimating()
                 table.reloadData()
                 table.isHidden = false
                 self.refreshControl.endRefreshing()
             }
         })
    }
    
    private func fetchData() {
        guard let table = self.table, let loadIndicator = self.loadIndicator else {
            print("couldn't connect starting vc outlets! bad things coming.....")
            return
        }
        loadIndicator.startAnimating() //POST 
        Networking.request(headers:nil, method: "GET", fullEndpoint: serverURL+"/articles", body: nil, completion: { data, response, error in
            if let dataExists = data, error == nil {
                do {
                    guard let list = try JSONSerialization.jsonObject(with: dataExists, options: .allowFragments) as? [Any]
                        else { throw NSError(domain: "invalid json", code: 1, userInfo: nil) }
                    
                    self.articles = list.compactMap({ try? ArticleBlurb(data: $0) })
                } catch let err {
                    print(data ?? "nil data")
                    print(err)
                    print("invalidddd")
                }
            }else{
                print("server disconnect, gotta do somethin here")
                //self.text[0] = "problem connecting to server";
            }
            
            DispatchQueue.main.async{
                let attributes = [NSAttributedString.Key.font: baseFont.withTextStyle(.subheadline)!]
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
        return self.articles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let attributes = [NSAttributedString.Key.font: baseFont.withTextStyle(.headline)!]
        let sub_at = [NSAttributedString.Key.font: baseFont.withTextStyle(.subheadline)!]
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath)
        if let cell: TitleSubtitleTableViewCell = cell as? TitleSubtitleTableViewCell {
            cell.title.attributedText = NSAttributedString.init(string:  self.articles[indexPath.item].title, attributes: attributes)
            cell.subtitle.attributedText = NSAttributedString.init(string: self.articles[indexPath.item].abstract ?? "", attributes: sub_at)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.link = self.articles[indexPath.item].url
        self.performSegue(withIdentifier: "startReading", sender: self)
    }
    

    @IBAction func startReading(_ sender: Any) {
        self.performSegue(withIdentifier: "startReading", sender: sender)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination
        if let destination: ArticleViewController = vc as? ArticleViewController {
            destination.mode = .read(viewModel: ReadArticleViewModel(articleLink: self.link))
//            destination.mode = .replay(viewModel: SessionReplayViewModel(articleLink: self.link))

            guard let a = UIApplication.shared.delegate as? AppDelegate else {return}
            a.autoRotate = false
            a.orientation = UIDevice.current.orientation
        }
    }
}
