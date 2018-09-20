//
//  ArticleViewController.swift
//  Scroll Data
//
//  Created by Arman Aydemir on 3/31/18.
//  Copyright © 2018 Arman Aydemir. All rights reserved.
//

import UIKit


@objc class ArticleViewController: UIViewController,UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {
    let version = "v0.2.0"
    var session_id: String?
    var text: Array<String> = []
    var cells: Array<String> = []
    var index_list: Array<String> = ["0"]
    let timeOffset:Double = 100000000
    var complete = false
    var startTime = CFAbsoluteTimeGetCurrent()
    var recent_last: String?
    var articleLink: String?
    var recent = [String]()
    var last_sent = CFAbsoluteTimeGetCurrent()
    let paragraphStyle = NSMutableParagraphStyle()
    let font: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
    var content_offset:CGFloat?
    let UDID = UIDevice.current.identifierForVendor!.uuidString
    var type: String?
    
    var checker:CGFloat?
    
    @IBOutlet weak var table: UITableView?
    @IBOutlet weak var spinner: UIActivityIndicatorView?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: .UIApplicationWillResignActive, object: nil)
        guard let table = self.table, let spinner = self.spinner else {
            print("couldn't connect outlets! bad things coming.....")
            return
        }
        
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        self.type = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 , value != 0 else { return identifier }
            return identifier! + String(UnicodeScalar(UInt8(value)))
        }
        
        let attributes = [NSFontAttributeName: font] as [String : Any]
        let model = UIDevice.current.model
        
        if(model == "iPad"){
            NSLayoutConstraint.activate([
                table.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
                table.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
                table.bottomAnchor.constraint(equalTo: view.readableContentGuide.bottomAnchor),
                table.topAnchor.constraint(equalTo: view.readableContentGuide.topAnchor)
            ])
        }
        
        
        table.separatorStyle = UITableViewCellSeparatorStyle.none
        table.isHidden = true;
        spinner.hidesWhenStopped = true
        spinner.startAnimating()
        let data: [String:Any] = ["article_link":self.articleLink ?? "", "UDID":self.UDID, "startTime":self.startTime*timeOffset, "type":self.type ?? "", "version":self.version]
        Networking.request(headers:nil, method: "POST", fullEndpoint: "http://159.203.207.54:22364/open_article", body: data, completion: { data, response, error in
            if let dataExists = data, error == nil {
                do {
                    if var text = try JSONSerialization.jsonObject(with: dataExists, options: .allowFragments) as? Array<String> {
                        self.session_id = text[0]
                        text.remove(at: 0)
                        self.text = text
                        self.cells = self.createCells(text: text, attributes: attributes)
                    } else {
                        throw NSError(domain: "invalid json", code: 1, userInfo: nil)
                    }
                }catch let err{
                    //this created an error where u hit back before it loads and it makes it go back twice creating a nothingness page
                    self.text = [err.localizedDescription, "Your copyboard had: " + self.articleLink! ]
                    self.cells = self.createCells(text: self.text, attributes: attributes)
                    print("invalid url!!")
                    //self.text[0] = err.localizedDescription;
                }
            }else{
                self.text = ["server disconnect"]
                self.cells = self.createCells(text: self.text, attributes: attributes)
                // _ = self.navigationController?.popViewController(animated: true)
                print("server disconnect, gotta do somethin here")
                //self.text[0] = "problem connecting to server";
            }
            
            DispatchQueue.main.async{
                spinner.stopAnimating()
                table.reloadData()
                //this could definitely be better
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(2000)) {
                    let timer = Timer.init(timeInterval: 0.01, repeats: true, block: { _ in
                            self.sendTextToServer(tableView: table)
                    })
                    RunLoop.main.add(timer, forMode: RunLoopMode.commonModes)
                    table.isHidden = false
                    self.sendTextToServer(tableView: table)
                }
            }
        })
        table.dataSource = self
        table.register(UINib.init(nibName: "TextCell", bundle: nil), forCellReuseIdentifier: "default")
        table.register(UINib.init(nibName: "TitleCellTableViewCell", bundle: nil), forCellReuseIdentifier: "title")
        table.delegate = self
        table.cellLayoutMarginsFollowReadableWidth = false
        table.estimatedRowHeight = 68.0
        table.rowHeight = UITableViewAutomaticDimension
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return UIScreen.main.bounds.size.height - (self.navigationController?.navigationBar.frame.size.height ?? 0) - 1
        default:
            return UITableViewAutomaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let aString = self.cells[indexPath.item]
        if(indexPath.item == 0){
            let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "title", for: indexPath)
            if let cell: TitleCellTableViewCell = cell as? TitleCellTableViewCell {
                let attributes = [NSFontAttributeName: font] as [String : Any]
                cell.titleText.attributedText = NSAttributedString.init(string: aString, attributes: attributes)
                cell.selectionStyle = .none
                cell.isSelected = false
            }
            return cell
        }else{
            let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath)
            if let cell: TextCell = cell as? TextCell {
                let attributes = [NSFontAttributeName: font] as [String : Any]
                cell.textSection.attributedText = NSAttributedString.init(string: aString, attributes: attributes)
                cell.isSelected = false
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(indexPath.item == self.cells.count-1){
            self.closeArticleWithServer()
            _ = navigationController?.popViewController(animated: true)
        }
    }
    
    func closeArticleWithServer() -> Void {
        print(self.session_id ?? "")
        print("sending end of data signal to server for this reading session")
        self.complete = true
    }
    
    func sendTextToServer(tableView:UITableView) -> Void {
        let current_offset = tableView.contentOffset.y
        if tableView.isHidden || current_offset == self.content_offset { return }
        self.content_offset = current_offset
        
        let cellsource = tableView.visibleCells[0..<tableView.visibleCells.endIndex].filter({ (cell) -> Bool in
            let parent = cell.superview!
            return parent.bounds.intersects(cell.frame)
        })
        let textsource = cellsource.flatMap({cell in if let cell: TextCell = cell as? TextCell{
                return cell.textSection.text
            }else{
                return "Title Card"
            }
        })
        if textsource.last == self.recent.last { return }
        self.recent = textsource
        var text = [String]()
        var section = [String]()
        for line in textsource{
            if(line == ""){
                text.append(section.joined(separator: " "))
                section = []
            }else{
                section.append(line)
            }
        } //this for loop combines the sections together so it comes in split the same way as server
        text.append(section.joined(separator: " "))
        //need to fix this stuff for at the end
        let first_index = tableView.indexPath(for: tableView.visibleCells.first!)?.item
        let second_index = tableView.indexPath(for: tableView.visibleCells.last!)?.item
        //print(index_list)
        //print(index_list[second_index!])
        //print(self.table?.indexPath(for: tableView.visibleCells[tableView.visibleCells.startIndex]))
        //print(self.table?.indexPath(for: tableView.visibleCells[tableView.visibleCells.endIndex]))
        let cur:CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
        //print(cur)
        //print(self.last_sent*timeOffset)
        let data: [String: Any] = ["UDID":self.UDID, "article":self.articleLink ?? "", "startTime":self.startTime*timeOffset, "appeared":self.last_sent*timeOffset, "time": cur*timeOffset, "first_line":index_list[first_index!] , "last_line":index_list[second_index!] , "previous_last_line":self.recent_last ?? "", "content_offset":content_offset ?? "error null" ]
        Networking.request(headers: nil, method: "POST", fullEndpoint: "http://159.203.207.54:22364/submit_data", body: data, completion:  { data, response, error in
            if let e = error {print(e)}
        })
        self.last_sent = cur
        self.recent_last = index_list[second_index!]
        
        
    }
    
    func cellFit(string:String, attributes:[String: Any]) -> Bool {
        guard let checker = self.checker else {
            //print("not table exists, this should never happen")
            print("error in cellFit")
            return false
        }
        
        return (string as NSString).size(attributes: attributes).width < checker - 32
    }
    
    //where we process the individual line cells
    func createCells(text:[String], attributes:[String:Any]) -> [String] {
        
        guard let table = self.table else {
            print("no table in createCells")
            return []
        }
        self.checker = min(table.frame.size.width, table.frame.size.height)
        var cells = [String].init()
        cells.append(text[0])
        var word_count = text[0].split(separator: " ").count
        index_list.append(word_count.description)
        for section in text.dropFirst(){
            var words = section.split(separator: " ").map({substring in
                return String.init(substring)
            })
            
            while(!words.isEmpty){
                var cell = [String]()
                var temp = [words[0]]
                while(!words.isEmpty && cellFit(string: temp.joined(separator: " "), attributes: attributes)){
                    cell.append(words.removeFirst())
                    if let w = words.first{
                        temp = cell
                        temp.append(w)
                    }
                }
                word_count += cell.count
                index_list.append(word_count.description)
                cells.append(cell.joined(separator: " "))
            }
            index_list.append(word_count.description)
            cells.append("")
        }
        cells.append("Tap here to submit data")
        return cells
    }
    
    @objc func willResignActive(_ notification: Notification) {
        _ = navigationController?.popViewController(animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let data: [String: Any] = ["UDID":self.UDID, "startTime":self.startTime*timeOffset, "article":self.articleLink ?? "", "time":CFAbsoluteTimeGetCurrent()*timeOffset, "session_id":self.session_id ?? "", "complete":self.complete]
        Networking.request(headers: nil, method: "POST", fullEndpoint: "http://159.203.207.54:22364/close_article", body: data, completion:  { data, response, error in
            if let e = error {print(e)}
        })
    }
}
