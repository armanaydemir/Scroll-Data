//
//  ArticleViewController.swift
//  Scroll Data
//
//  Created by Arman Aydemir on 3/31/18.
//  Copyright © 2018 Arman Aydemir. All rights reserved.
//

import UIKit


@objc class ArticleViewController: UIViewController,UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {
    
    var throttle = true
    var text: Array<String> = []
    var cells: Array<String> = []
    var startTime = Date();
    var recent: Dictionary<AnyHashable, String>?
    var articleLink: String?
    let paragraphStyle = NSMutableParagraphStyle()
    let font:UIFont! = UIFont.init(name: "Palatino-Roman", size: 11.5) as UIFont?
    
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.paragraphStyle.minimumLineHeight = 25
        self.paragraphStyle.maximumLineHeight = 25
        let attributes = [NSFontAttributeName: font] as [String : Any]
        
        self.table.separatorStyle = UITableViewCellSeparatorStyle.none
        self.table.isHidden = true;
        self.spinner.hidesWhenStopped = true
        self.spinner.startAnimating()
        Networking.request(headers:nil, method: "GET", fullEndpoint: "http://159.203.207.54:22364", body: ["articleLink":self.articleLink ?? ""], completion: { data, response, error in
            if(error == nil){
                if let dataExists = data {
                    do {
                        self.text = try JSONSerialization.jsonObject(with: dataExists, options: .allowFragments) as! Array<String>
                        self.cells = self.createCells(text: self.text, attributes: attributes)
                    }catch let err{
                        self.text[0] = err.localizedDescription;
                    }
                }
            }else{
                self.text[0] = "problem connecting to server";
            }
            DispatchQueue.main.async{
                self.spinner?.stopAnimating()
                self.throttle = false
                self.table?.isHidden = false
                self.table?.reloadData()
            }
        })
        self.table?.dataSource = self
        self.table?.register(UINib.init(nibName: "TextCell", bundle: nil), forCellReuseIdentifier: "default")
        self.table?.delegate = self
        self.table?.cellLayoutMarginsFollowReadableWidth = false
        self.table?.estimatedRowHeight = 68.0
        self.table?.rowHeight = UITableViewAutomaticDimension
        
        
        let timer = Timer.init(timeInterval: 0.2, target: self, selector: #selector(self.timerFireMethod(timer:)), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: RunLoopMode.commonModes)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:TextCell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath) as! TextCell
        let aString = self.cells[indexPath.item]
        let attributes = [NSFontAttributeName: font] as [String : Any]
        cell.textSection.attributedText = NSAttributedString.init(string: aString, attributes: attributes)
        cell.isSelected = false
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.sendTextToServer(tableView: tableView)
    }
    
    func sendTextToServer(tableView:UITableView) -> Void {
        let text = tableView.visibleCells.flatMap({cell in (cell as! TextCell).textSection.text})
        print("scrolled")
        print(text.first ?? "empty first")
        print(text.last ?? "empty last")
    }
    
    func timerFireMethod(timer:Timer) {
        self.throttle = false;
    }
    
    func cellFit(string:String, attributes:[String: Any]) -> Bool {
        return (string as NSString).size(attributes: attributes).width < min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) - 32
    }
    
    //where we process the individual line cells
    func createCells(text:[String], attributes:[String:Any]) -> [String] {
        var cells = [""]
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
        return cells
    }
}
