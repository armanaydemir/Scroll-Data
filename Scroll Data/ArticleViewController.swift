//
//  ArticleViewController.swift
//  Scroll Data
//
//  Created by Arman Aydemir on 3/31/18.
//  Copyright © 2018 Arman Aydemir. All rights reserved.
//

import UIKit


@objc class ArticleViewController: UIViewController,UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {
    let version = "v0.2.7"
    var session_id: String?
    var text: Array<String> = []
    var cells: Array<String> = []
    var index_list: Array<String> = ["0"]
    let timeOffset:Double = 100000000
    var complete = false
    var startTime = CFAbsoluteTimeGetCurrent()
    var recent_first: Int?
    var recent_last: Int?
    var articleLink: String?
    var recent = [String]()
    var last_sent = CFAbsoluteTimeGetCurrent()
    let paragraphStyle = NSMutableParagraphStyle()
    
    var font: UIFont = UIFont.init(name: "Times New Roman", size: UIFont.systemFontSize) ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
    let titleFont = SystemFont.init(fontName: "Times New Roman")?.getFont(withTextStyle: .title1) ?? UIFont.preferredFont(forTextStyle: .title1)
    var content_offset:CGFloat?
    let UDID = UIDevice.current.identifierForVendor!.uuidString
    var type: String?
    let timePerCheck = 0.00001
    
    var checker:CGFloat?
    
    @IBOutlet weak var table: UITableView?
    @IBOutlet weak var spinner: UIActivityIndicatorView?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: .UIApplicationWillResignActive, object: nil)
        guard let table = self.table, let spinner = self.spinner else {
            print("couldn't connect outlets! bad things coming.....")
            return
        }
        table.isHidden = true;
        table.accessibilityIdentifier = "articleTable"
        spinner.hidesWhenStopped = true
        spinner.startAnimating()
        
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        self.type = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 , value != 0 else { return identifier }
            return identifier! + String(UnicodeScalar(UInt8(value)))
        }
        let model = UIDevice.current.model
        if(model == "iPad"){
//            NSLayoutConstraint.activate([
//                table.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
//                table.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
//                table.bottomAnchor.constraint(equalTo: view.readableContentGuide.bottomAnchor),
//                table.topAnchor.constraint(equalTo: view.readableContentGuide.topAnchor)
//                ])
             self.view.layoutIfNeeded()
        }
       
        
        self.font = findFontSize(table:self.table!) ?? UIFont.preferredFont(forTextStyle: .body)
        let attributes = [NSFontAttributeName: font] as [String : Any]
        
        
        table.separatorStyle = UITableViewCellSeparatorStyle.none
        
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
                
                table.reloadData()
                //this could definitely be better
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(2000)) {
                    let timer = Timer.init(timeInterval: self.timePerCheck, repeats: true, block: { _ in
                        self.sendTextToServer(tableView: table)
                    })
                    RunLoop.main.add(timer, forMode: RunLoopMode.commonModes)
                    spinner.stopAnimating()
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
    
    func findFontSize(table:UITableView) -> UIFont? {
        let string = """
President Trump’s $1.5 trillion tax cut was supposed to be a big selling point for congressional Republicans in the midterm elections. Instead, it appears to have done more to hurt, than help, Republicans in high-tax districts across California, New Jersey, Virginia and other states.

House Republicans suffered heavy Election Day losses in districts where large concentrations of taxpayers claim a popular tax break — the state and local tax deduction — which the law capped at $10,000 per household. The new limit resulted in an effective tax increase for high-earning residents of high-tax states who claim more than $10,000 per year in SALT.

Democrats swept four Republican-held districts in Orange County, Calif., where at least 40 percent of taxpayers claim the SALT tax break, defeating a pair of Republican incumbents and winning seats vacated by Representatives Ed Royce and Darrell Issa. Those districts include longtime Republican strongholds, like Newport Beach, and rank among the country’s largest users of the state and local tax break.
"""
        let height = (UIScreen.main.bounds.height-(self.view.safeAreaInsets.top + self.view.safeAreaInsets.bottom))
        let size = CGSize.init(width: table.frame.width-32, height: height)
        return SystemFont.init(fontName: "Times New Roman")?.fontToFit(text: string, inSize: size, spacing: 8.0)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return UIScreen.main.bounds.size.height - (self.navigationController?.navigationBar.frame.size.height ?? 0) - 1
        case (self.cells.count-1):
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
                let attributes = [NSFontAttributeName: self.titleFont] as [String : Any]
                cell.titleText.attributedText = NSAttributedString.init(string: aString, attributes: attributes)
                cell.selectionStyle = .none
                cell.isSelected = false
                cell.accessibilityLabel = "titleCell"
            }
            return cell
        }else if(indexPath.item == self.cells.count-1){
            let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "title", for: indexPath)
            if let cell: TitleCellTableViewCell = cell as? TitleCellTableViewCell {
                let attributes = [NSFontAttributeName: font] as [String : Any]
                cell.titleText.attributedText = NSAttributedString.init(string: aString, attributes: attributes)
                cell.selectionStyle = .none
                cell.isSelected = false
                cell.accessibilityLabel = "submitCell"
            }
            return cell
        }else{
            let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath)
            if let cell: TextCell = cell as? TextCell {
                let attributes = [NSFontAttributeName: font] as [String : Any]
                cell.textSection.attributedText = NSAttributedString.init(string: aString, attributes: attributes)
                cell.isSelected = false
                cell.accessibilityLabel = "textCell"
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
    
    func getTextFromScreen(tableView:UITableView) -> Array<String> {
        let visibleCells = tableView.visibleCells.filter({ (cell) -> Bool in
            let parent = cell.superview!
            return parent.bounds.intersects(cell.frame)
        })
        
        let textsource = visibleCells.flatMap({cell in if let cell: TextCell = cell as? TextCell{
            return cell.textSection.text
        }else if let cell: TitleCellTableViewCell = cell as? TitleCellTableViewCell{
            return cell.titleText.text
        }else{
            return "this shouldnt be possible?"
            }
        })
        
        return textsource;
    }
    
    func currentPosition(tableView:UITableView, textsource: Array<String>) -> Array<Int> {
        let current_offset = tableView.contentOffset.y
        var first_index: Int?
        var second_index: Int?
        if(current_offset >= self.content_offset ?? 0){
            first_index = self.cells[(self.recent_first ?? 0)..<self.cells.endIndex].firstIndex(of: textsource.first!)
            second_index = self.cells[(self.recent_last ?? 0)..<self.cells.endIndex].firstIndex(of: textsource.last!)
        }else{
            first_index = self.cells[0..<(self.recent_first ?? 0)+1].lastIndex(of: textsource.first!)
            second_index = self.cells[0..<(self.recent_last ?? 0)+1].lastIndex(of: textsource.last!)
        }
        
//        if(self.recent.count-2 >= 0 && textsource[textsource.count-2] != self.recent.last){
//            print("text skip")
//        }
//        if(second_index! - 1 != self.recent_last ?? 0){
//            print("index skip \(second_index)")
//        }
        //35, 60, 155, 
        self.content_offset = current_offset
        return [first_index!, second_index!]
    }
    
    func sendTextToServer(tableView:UITableView) -> Void {
        //print("send text - \(CFAbsoluteTimeGetCurrent())")
        let current_offset = tableView.contentOffset.y
        if tableView.isHidden || current_offset == self.content_offset { return }
        
        let textsource = getTextFromScreen(tableView: tableView)
        if textsource.last == self.recent.last { return }
       
        let temp = currentPosition(tableView: tableView, textsource: textsource)
        let first_index = temp[0], second_index = temp[1]
        
        let cur:CFAbsoluteTime = CFAbsoluteTimeGetCurrent()

        //print(second_index)
        //print(first_index)
        let data: [String: Any] = ["UDID":self.UDID, "article":self.articleLink ?? "", "startTime":self.startTime*timeOffset, "appeared":self.last_sent*timeOffset, "time": cur*timeOffset, "first_cell":first_index, "last_cell":second_index ,"previous_first_cell":self.recent_first ?? "", "previous_last_cell":self.recent_last ?? "", "content_offset":content_offset ?? "error null" ]
        Networking.request(headers: nil, method: "POST", fullEndpoint: "http://159.203.207.54:22364/submit_data", body: data, completion:  { data, response, error in
            if let e = error {print(e)}
        })
        // print(data)
        
        self.last_sent = cur
        self.recent_last = second_index
        self.recent_first = first_index
        self.recent = textsource
        
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
        DispatchQueue.main.async {
             self.checker = min(table.frame.size.width, table.frame.size.height)
        }
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
            index_list.append("-")
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
        let data: [String: Any] = ["UDID":self.UDID, "startTime":self.startTime*timeOffset, "article":self.articleLink ?? "", "time":CFAbsoluteTimeGetCurrent()*timeOffset, "session_id":self.session_id ?? "", "complete":self.complete, "line_splits":index_list]
        Networking.request(headers: nil, method: "POST", fullEndpoint: "http://159.203.207.54:22364/close_article", body: data, completion:  { data, response, error in
            if let e = error {print(e)}
        })
    }
}
