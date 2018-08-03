//
//  ArticleViewController.swift
//  Scroll Data
//
//  Created by Arman Aydemir on 3/31/18.
//  Copyright © 2018 Arman Aydemir. All rights reserved.
//

import UIKit


@objc class ArticleViewController: UIViewController,UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {
    
    var text: Array<String> = []
    var cells: Array<String> = []
    var startTime = Date();
    var startString: String?
    var articleLink: String?
    var recent = [String]()
    var last_sent = Date();
    let paragraphStyle = NSMutableParagraphStyle()
    let font: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
    var content_offset:CGFloat?
    let UDID = UIDevice.current.identifierForVendor!.uuidString
    var type: String?
    let formatter = DateFormatter()
    
    @IBOutlet weak var table: UITableView?
    @IBOutlet weak var spinner: UIActivityIndicatorView?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
    
        self.formatter.setLocalizedDateFormatFromTemplate("dd-MM-yyyy HH:mm:ss.SSS")
        self.startString = formatter.string(from: self.startTime)
        
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
        Networking.request(headers:nil, method: "GET", fullEndpoint: "http://159.203.207.54:22364", body: ["articleLink":self.articleLink ?? ""], completion: { data, response, error in
            if let dataExists = data, error == nil {
                do {
                    if let text = try JSONSerialization.jsonObject(with: dataExists, options: .allowFragments) as? Array<String> {
                        self.text = text
                        self.cells = self.createCells(text: text, attributes: attributes)
                    } else {
                        throw NSError(domain: "invalid json", code: 1, userInfo: nil)
                    }
                }catch let err{
                    self.text[0] = err.localizedDescription;
                }
            }else{
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
        print("sending end of data signal to server for this reading session")
        let data: [String: Any] = ["UDID":self.UDID, "type":self.type ?? "", "startTime":self.startString ?? "", "article":self.articleLink ?? ""]
        Networking.request(headers: nil, method: "POST", fullEndpoint: "http://159.203.207.54:22364/close_article", body: data, completion:  { data, response, error in
            if let e = error {print(e)}
        })
    }
    
    func sendTextToServer(tableView:UITableView) -> Void {
        let current_offset = tableView.contentOffset.y
        if tableView.isHidden || current_offset == self.content_offset { return }
        self.content_offset = current_offset
        let textsource = tableView.visibleCells[0..<tableView.visibleCells.endIndex].filter({ (cell) -> Bool in
            let parent = cell.superview!
            return parent.bounds.intersects(cell.frame)
        }).flatMap({cell in if let cell: TextCell = cell as? TextCell{
                return cell.textSection.text
            }else{
                return "Title Card"
            }
        })
        if textsource.first != "Title Card" && textsource.first == self.recent.first { return } //if statement is for repeats that happen at head of csv file (right when screen loads)
            //but this if statement doesnt fix the problem
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
        
        
        let cur = Date()
        let currentString = self.formatter.string(from: cur)
        let last_sent_string = self.formatter.string(from: self.last_sent)
        let data: [String: Any] = ["UDID":self.UDID, "type":self.type ?? "", "appeared":last_sent_string, "time": currentString, "article":self.articleLink ?? "", "first_line":textsource.first ?? "", "last_line":textsource.last ?? "", "content_offset":content_offset]
        Networking.request(headers: nil, method: "POST", fullEndpoint: "http://159.203.207.54:22364/submit_data", body: data, completion:  { data, response, error in
            if let e = error {print(e)}
        })
        self.last_sent = Date()
        
        
    }
    
    func cellFit(string:String, attributes:[String: Any]) -> Bool {
        guard let table = self.table else {
            print("not table exists, this should never happen")
            return false
        }
        
        let checker = min(table.frame.size.width, table.frame.size.height)
        return (string as NSString).size(attributes: attributes).width < checker - 32
    }
    
    //where we process the individual line cells
    func createCells(text:[String], attributes:[String:Any]) -> [String] {
        var cells = [String].init()
        for section in text{
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
                
                cells.append(cell.joined(separator: " "))
            }
            cells.append("")
        }
        cells.append("Tap here to submit data")
        return cells
    }
}
