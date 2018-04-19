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
    var articleLink: String?
    let paragraphStyle = NSMutableParagraphStyle()
    let font: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
    
    @IBOutlet weak var table: UITableView?
    @IBOutlet weak var spinner: UIActivityIndicatorView?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let table = self.table, let spinner = self.spinner else {
            print("couldn't connect outlets! bad things coming.....")
            return
        }
        
        
        self.paragraphStyle.minimumLineHeight = 25
        self.paragraphStyle.maximumLineHeight = 25
        let attributes = [NSFontAttributeName: font] as [String : Any]
        
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
                table.isHidden = false
                table.reloadData()
            }
        })
        table.dataSource = self
        table.register(UINib.init(nibName: "TextCell", bundle: nil), forCellReuseIdentifier: "default")
        table.delegate = self
        table.cellLayoutMarginsFollowReadableWidth = false
        table.estimatedRowHeight = 68.0
        table.rowHeight = UITableViewAutomaticDimension
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath)
        if let cell: TextCell = cell as? TextCell {
            let aString = self.cells[indexPath.item]
            let attributes = [NSFontAttributeName: font] as [String : Any]
            cell.textSection.attributedText = NSAttributedString.init(string: aString, attributes: attributes)
            cell.isSelected = false
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.sendTextToServer(tableView: tableView)
    }
    
    func sendTextToServer(tableView:UITableView) -> Void {
        let textsource = tableView.visibleCells.flatMap({cell in (cell as! TextCell).textSection.text})
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
        
        
        let UDID = UIDevice.current.identifierForVendor!.uuidString
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let type = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 , value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("dd-MM-yyyy HH:mm:ss.SSS")
        let cur = Date()
        let currentString = formatter.string(from: cur)
        let startString = formatter.string(from: self.startTime)

        let data: [String: Any] = ["UDID":UDID, "type":type, "startTime":startString, "time": currentString, "article":self.articleLink ?? "", "text":text]
        Networking.request(headers: nil, method: "POST", fullEndpoint: "http://159.203.207.54:22364/submit_data", body: data, completion:  { data, response, error in
            if let e = error {print(e)}
        })
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
