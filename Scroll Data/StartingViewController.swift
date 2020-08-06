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
        
        func name() -> String {
            switch self {
            case .articles: return "Articles"
            case .sessions: return "Sessions"
            }
        }
    }
    
    private var tableMode: TableMode = .articles {
        didSet {
            switch tableMode {
            case .articles:
                table.reloadData()
                if articles.isEmpty {
                    fetchData(fromEmpty: true)
                }
                
            case .sessions:
                table.reloadData()
                if sessions.isEmpty {
                    fetchSessions(fromEmpty: true)
                }
            }
        }
    }
    
    private let refreshControl = UIRefreshControl()
    
    var articles: [ArticleBlurb] = []
    var sessions: [SessionBlurb] = []
    
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
        
        loadIndicator.startAnimating()
        table.isHidden = true;
        table.accessibilityIdentifier = "startingTable"
        table.dataSource = self
        table.delegate = self
        table.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        
        checkSettings { settings in
            DispatchQueue.main.async {
                if settings.showSessions {
                    let segmentedControl = UISegmentedControl.init(items: [TableMode.articles.name(), TableMode.sessions.name()])
                    segmentedControl.selectedSegmentIndex = self.tableMode.rawValue
                    segmentedControl.addTarget(self, action: #selector(self.switchedTable(segmentedControl:)), for: .valueChanged)
                    self.navigationItem.titleView = segmentedControl
                    switch self.tableMode {
                        case .articles: self.fetchData(fromEmpty: true)
                        case .sessions: self.fetchSessions(fromEmpty: true)
                    }
                } else {
                    self.tableMode = .articles
                    self.navigationItem.title = TableMode.articles.name()
                }
                
                table.register(UINib.init(nibName: "TitleSubtitleTableViewCell", bundle: nil), forCellReuseIdentifier: "default")
                table.rowHeight = UITableView.automaticDimension
            }
        }

    }
    
    private func checkSettings(completion: @escaping (_ settings: Settings) -> Void) {
        Server.Request.settings.startRequest { (result: Result<Settings, Swift.Error>) in
            switch result {
            case .success(let settings):
                completion(settings)
            case .failure(let error):
                print(error)
                completion(Settings()) //return the defaults if there's an issue
            }
        }
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
    
    private func fetchSessions(fromEmpty: Bool) {
        guard let table = self.table, let loadIndicator = self.loadIndicator else {
             print("couldn't connect starting vc outlets! bad things coming.....")
             return
        }
        
        if fromEmpty {
            self.table.isHidden = true
            loadIndicator.startAnimating()
        }
        
        Server.Request.sessions.log().startRequest { (result: Result<[SessionBlurb], Swift.Error>) in
            switch result {
            case .failure(let error):
                 print(error)
            case .success(let sessions):
                self.sessions = sessions
                DispatchQueue.main.async{
                    let attributes = [NSAttributedString.Key.font: baseFont.withTextStyle(.subheadline)!]
                    self.refreshControl.attributedTitle = NSAttributedString(string: (Date().description), attributes: attributes)
                    loadIndicator.stopAnimating()
                    table.reloadData()
                    table.isHidden = false
                    self.refreshControl.endRefreshing()
                }
            }
        }
    }
    
    private func fetchData(fromEmpty: Bool) {
        guard let table = self.table, let loadIndicator = self.loadIndicator else {
            print("couldn't connect starting vc outlets! bad things coming.....")
            return
        }
        
        if fromEmpty {
            self.table.isHidden = true
            loadIndicator.startAnimating() //POST
        }
        
        Server.Request.articles.log().startRequest { (result: Result<[ArticleBlurb], Swift.Error>) in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let articles):
                self.articles = articles
                DispatchQueue.main.async{
                    let attributes = [NSAttributedString.Key.font: baseFont.withTextStyle(.subheadline)!]
                    self.refreshControl.attributedTitle = NSAttributedString(string: (Date().description), attributes: attributes)
                    loadIndicator.stopAnimating()
                    table.reloadData()
                    table.isHidden = false
                    self.refreshControl.endRefreshing()
                }
            }
        }
    }
    
    @objc private func refreshData(_ sender: Any) {
        switch tableMode {
        case .articles:
            fetchData(fromEmpty: false)
        case .sessions:
            fetchSessions(fromEmpty: false)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableMode {
        case .articles:
            return self.articles.count
        case .sessions:
            return self.sessions.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let title: String
        let subtitle: String
        
        switch tableMode {
        case .articles:
            let article = self.articles[indexPath.item]
            title = article.title
            subtitle = article.abstract ?? ""
        case .sessions:
            let session = self.sessions[indexPath.item]
            title = session.article.title
            subtitle = "\(session.id) -  \(session.deviceType ?? "") - \(session.readerVersion ?? "")"
        }
        
        let attributes = [NSAttributedString.Key.font: baseFont.withTextStyle(.headline)!]
        let sub_at = [NSAttributedString.Key.font: baseFont.withTextStyle(.subheadline)!]
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath)
        if let cell: TitleSubtitleTableViewCell = cell as? TitleSubtitleTableViewCell {
            cell.title.attributedText = NSAttributedString.init(string:  title, attributes: attributes)
            cell.subtitle.attributedText = NSAttributedString.init(string: subtitle, attributes: sub_at)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch tableMode {
        case .articles:
            self.link = self.articles[indexPath.item].url
        case .sessions:
            self.link = self.sessions[indexPath.item].id
        }
        
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
            switch tableMode {
            case .articles:
                destination.mode = .read(viewModel: ReadArticleViewModel(articleLink: self.link))
            case .sessions:
                destination.mode = .replay(viewModel: SessionReplayViewModel(sessionID: self.link))
            }
        }
    }
}
