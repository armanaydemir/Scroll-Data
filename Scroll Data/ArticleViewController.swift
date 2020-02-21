//
//  ArticleViewController.swift
//  Scroll Data
//
//  Created by Arman Aydemir on 3/31/18.
//  Copyright © 2018 Arman Aydemir. All rights reserved.
//

import UIKit


@objc class ArticleViewController: UIViewController {
    //let scroll_type = "exact" //"scroll_every_x"
    let scroll_type = "exact"
    var content: Array<Content> = []
    var articleLink: String?
    var vm: ArticleViewModel! = nil
    var complete = false
    var scrollOffset = 0.0
    var time_offset = 100000000.0
    var data: [String:Any]  = [:]
    
    let paragraphStyle = NSMutableParagraphStyle()
    
    var font: UIFont = UIFont.init(name: "Times New Roman", size: UIFont.systemFontSize) ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
    let titleFont = SystemFont.init(fontName: "Times New Roman")?.getFont(withTextStyle: .title1) ?? UIFont.preferredFont(forTextStyle: .title1)
    var content_offset:CGFloat?
   
    let timePerCheck = 0.00001
    let timePerScroll = 0.001
    var lastTime = CFAbsoluteTimeGetCurrent()
    let timeBetweenScroll = 4.0
    var timer: Timer? = nil
    
    var scrollIndex = 1
    var scroll_timer: Timer? = nil
    
    var minTableDim:CGFloat?
    
    @IBOutlet weak var table: UITableView?
    @IBOutlet weak var spinner: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let table = self.table, let spinner = self.spinner else {
            print("couldn't connect outlets! bad things coming.....")
            return
        }
        
        
        //NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        
        vm = ArticleViewModel.init(articleLink: self.articleLink!)
        
        table.isHidden = true;
        table.accessibilityIdentifier = "articleTable"
        table.separatorStyle = UITableViewCell.SeparatorStyle.none
        table.dataSource = self
        table.register(UINib.init(nibName: "ArticleTextTableViewCell", bundle: nil), forCellReuseIdentifier: "default")
        table.register(UINib.init(nibName: "TitleCellTableViewCell", bundle: nil), forCellReuseIdentifier: "title")
        table.register(UINib.init(nibName: "SubmitTableViewCell", bundle: nil), forCellReuseIdentifier: "submit")
        table.delegate = self
        table.cellLayoutMarginsFollowReadableWidth = false
        table.estimatedRowHeight = 68.0
        table.rowHeight = UITableView.automaticDimension

        spinner.hidesWhenStopped = true
        spinner.startAnimating()
        
        let model = UIDevice.current.model.lowercased()
        if(model.contains("ipad")){
            NSLayoutConstraint.activate([
                table.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
                table.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
                table.bottomAnchor.constraint(equalTo: view.readableContentGuide.bottomAnchor),
                table.topAnchor.constraint(equalTo: view.readableContentGuide.topAnchor)
                ])
            self.view.layoutIfNeeded()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        guard let table = self.table else {
            print("couldn't connect outlets! bad things coming.....")
            return
        }

        DispatchQueue.main.async {
            self.minTableDim = min(table.frame.size.width, table.frame.size.height)
        }
        
        vm.fetchText(completion: { data, error in
            guard case let p as [String] = data["paragraphs"] else {
                let alert = UIAlertController.init(title: "error fetching text", message: error, preferredStyle: UIAlertController.Style.alert)
                self.present(alert, animated: true, completion: nil)
                return
            }
            DispatchQueue.main.async {
                self.font = self.findFontSize(table: table) ?? UIFont.preferredFont(forTextStyle: .body)
                let content = self.convert(paragraphs: p, font: self.font)
                self.content = content
                self.data = data
                
                table.reloadData()
                
                self.repeatingCheck(table: table)
            }
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        let lines = self.content.filter { return !$0.spacer }
        let wordIndices = lines.map { $0.firstWordIndex }
        let characterIndices = lines.map { $0.firstCharacterIndex }
        
        self.timer?.invalidate()
        self.scroll_timer?.invalidate()
        
        self.vm.closeArticle(content: self.content.map { $0.toDictionary() }, wordIndicies: wordIndices, characterIndicies: characterIndices, complete: self.complete)
        
        guard let a = UIApplication.shared.delegate as? AppDelegate else {return}
        a.autoRotate = true
    }
    
    func scrollEventTrigger(table: UITableView) {
        //print(data["version"])
        print("scroll event triggered")
        guard case let s as Array<[String:Any]> = data["session_data"] else {
            let alert = UIAlertController.init(title: "error fetching session data", message: nil, preferredStyle: UIAlertController.Style.alert)
            self.present(alert, animated: true, completion: nil)
            return
        }
        //make check for scrollIndex in bounds
        //print(s)
        guard case let v as String = data["version"] else {
            let alert = UIAlertController.init(title: "error fetching version", message: nil, preferredStyle: UIAlertController.Style.alert)
            self.present(alert, animated: true, completion: nil)
            return
        }
        var t1 = -1
        var t2 = -1
        //print(v)
        
        
        if(v == "v0.2.6" || v == "v0.2.7"){
            t1 = Int(s[scrollIndex]["appeared"] as! NSNumber)
            t2 = Int(s[scrollIndex-1]["appeared"] as! NSNumber)
        }else{
            t1 = Int(s[scrollIndex]["time"] as! NSNumber)
            t2 = Int(s[scrollIndex-1]["time"] as! NSNumber)
        }
        //print(s[self.scrollIndex]["last_cell"])
        guard case let last_cell as Int = s[self.scrollIndex]["last_cell"]  else {
            let alert = UIAlertController.init(title: "error fetching last cell", message: nil, preferredStyle: UIAlertController.Style.alert)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        guard case let first_cell as Int = s[self.scrollIndex]["first_cell"]  else {
            let alert = UIAlertController.init(title: "error fetching last cell", message: nil, preferredStyle: UIAlertController.Style.alert)
            self.present(alert, animated: true, completion: nil)
            return
        }
        guard let first = table.visibleCells.first,
            let first_index = table.indexPath(for: first)?.item,
            let second = table.visibleCells.last,
            let last_index = table.indexPath(for: second)?.item
            else {
                print("no visible cells")
                return
        }

        
//        guard case let offset as CGFloat = s[scrollIndex]["content_offset"] else {
//            let alert = UIAlertController.init(title: "error fetching offset", message: nil, preferredStyle: UIAlertController.Style.alert)
//            self.present(alert, animated: true, completion: nil)
//            return
//        }
        
        let t = TimeInterval(Double(t1-t2)/self.time_offset)
        DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
            self.table?.layer.removeAllAnimations()
            //let temp = CFAbsoluteTimeGetCurrent()
            print("about to scroll")
            if(first_cell>1){
                UIView.animate(withDuration: t, delay: 0, options: UIView.AnimationOptions.allowUserInteraction, animations: {table.scrollToRow(at: IndexPath.init(item: first_cell, section: 0), at: UITableView.ScrollPosition.top, animated: false)}, completion: { _ in print("Done") })
            }else if(last_cell<table.numberOfRows(inSection: 0)-1){ //dont really need this check
                UIView.animate(withDuration: t, delay: 0, options: UIView.AnimationOptions.allowUserInteraction, animations: {table.scrollToRow(at: IndexPath.init(item: last_cell, section: 0), at: UITableView.ScrollPosition.bottom, animated: false)}, completion: { _ in print("Done") })
            }
        })
        scrollIndex += 1
        if(scrollIndex < s.count-1){
            self.scroll_timer = Timer.init(timeInterval: t*0.9, repeats: false, block: { _ in
                self.scrollEventTrigger(table: table)
            })
            print("starting timer")
            RunLoop.main.add(self.scroll_timer!, forMode: RunLoop.Mode.common)
        }else{
            _ = navigationController?.popViewController(animated: true)
        }
        
    }

    @objc func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        //print("woahhh")
        self.table?.layer.removeAllAnimations()
        scroll_timer?.invalidate()
        timer?.invalidate()
    }
    
    @objc func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let table = self.table else {
            print("error connecting table")
            return
        }
        self.scrollEventTrigger(table: table)
    }
    @objc func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard let table = self.table else{
            print("error connecting table")
            return
        }
        if(!decelerate){
            self.scrollEventTrigger(table: table)
        }
    }
    
    func repeatingCheck(table: UITableView) {
        DispatchQueue.main.asyncAfter(deadline: .now()+1) {

            self.spinner?.stopAnimating()
            table.isHidden = false
            table.dragInteractionEnabled = true
            self.scrollEventTrigger(table: table)
            
        }
    }
    
    func findFontSize(table:UITableView) -> UIFont? {
        let string = sizingString
        let height = viewableAreaHeight(showOnBottom: false)
        let size = CGSize.init(width: table.frame.width-ArticleTextTableViewCell.widthSpacingConstant*2, height: height)
        return SystemFont.init(fontName: "Times New Roman")?.fontToFit(text: string, inSize: size, spacing: ArticleTextTableViewCell.topSpacingConstant*2)
    }
    
    func sendTextToServer(tableView:UITableView) -> Void {
        let current_offset = tableView.contentOffset.y
        
        guard current_offset != self.content_offset && !tableView.isHidden
            else {
                print("table not visible or no content offset change")
                return
        }
        
        guard let first = tableView.visibleCells.first,
            let first_index = tableView.indexPath(for: first)?.item,
            let second = tableView.visibleCells.last,
            let last_index = tableView.indexPath(for: second)?.item
            else {
                print("no visible cells")
                return
        }
        
        vm.submitData(content_offset: current_offset, first_index: first_index, last_index: last_index)
    }
    
    func cellFit(string:String, attributes: [NSAttributedString.Key: Any]) -> Bool {
        guard let checker = self.minTableDim else {
            //print("not table exists, this should never happen")
            print("error in cellFit")
            return false
        }
        
        return (string as NSString).size(withAttributes: attributes).width < checker - ArticleTextTableViewCell.widthSpacingConstant*2
    }

    
    @objc func willResignActive(_ notification: Notification) {
        _ = navigationController?.popViewController(animated: true)
    }
    
    
    func convert(paragraphs: [String], font: UIFont) -> [Content] {
        var cells = [Content].init()
        var p = 0
        var word_count = 0
        var char_count = 0
        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font]
        cells.append(Content.init(text: paragraphs[0], paragraph: p, firstWordIndex: word_count, firstCharacterIndex: char_count, spacer: false))
        p+=1
        for section in paragraphs.dropFirst(){
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
                let current_text = cell.joined(separator: " ")
                char_count += current_text.count
                cells.append(Content.init(text: current_text, paragraph: p, firstWordIndex: word_count, firstCharacterIndex: char_count, spacer: false))

            }
            p += 1
            cells.append(Content.init(text: "", paragraph: p, firstWordIndex: word_count, firstCharacterIndex: char_count, spacer: true))
        }
        return cells
    }
    
    func viewableAreaHeight(showOnBottom: Bool) -> CGFloat {
        var viewableHeight = UIScreen.main.bounds.height - self.view.safeAreaInsets.top
        if !showOnBottom { viewableHeight = viewableHeight - self.view.safeAreaInsets.bottom }
        return viewableHeight
    }
}

extension ArticleViewController: SubmitTableViewCellDelegate {
    func submitData() {
        self.complete = true
        _ = navigationController?.popViewController(animated: true)
    }
}

extension ArticleViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.content.count > 0) ? self.content.count + 1 : 0 //plus one for submit button
    }
    

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(indexPath.item == self.content.count){
            let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "submit", for: indexPath)
            if let cell: SubmitTableViewCell = cell as? SubmitTableViewCell {
                cell.submitButton.setTitle("Tap to submit data", for: UIControl.State.normal)
                cell.selectionStyle = .none
                cell.isSelected = false
                cell.accessibilityLabel = "submitCell"
                cell.delegate = self
            }
            return cell
        }else{
            let aString = self.content[indexPath.item].text
            if(indexPath.item == 0){
                let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "title", for: indexPath)
                if let cell: TitleCellTableViewCell = cell as? TitleCellTableViewCell {
                    let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: self.titleFont]
                    cell.titleText.attributedText = NSAttributedString.init(string: aString, attributes: attributes)
                    cell.selectionStyle = .none
                    cell.isSelected = false
                    cell.isUserInteractionEnabled = false
                    cell.accessibilityLabel = "titleCell"
                }
                return cell
            }else{
                let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath)
                if let cell: ArticleTextTableViewCell = cell as? ArticleTextTableViewCell {
                    let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font]
                    cell.textSection.attributedText = NSAttributedString.init(string: aString, attributes: attributes)
                    cell.isSelected = false
                    cell.isUserInteractionEnabled = false
                    cell.accessibilityLabel = "textCell"
                }
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return viewableAreaHeight(showOnBottom: true)
        case self.content.count:
            return viewableAreaHeight(showOnBottom: false)
        default:
            return UITableView.automaticDimension
        }
    }
}

struct Content: Codable {
    let text: String
    let paragraph: Int
    let firstWordIndex: Int
    let firstCharacterIndex: Int
    let spacer: Bool
    
    func toDictionary() -> [String : Any] {
        return [
            "text" : text,
            "paragraph" : paragraph,
            "first_word_index" : firstWordIndex,
            "first_character_index" : firstCharacterIndex,
            "spacer" : spacer
        ]
    }
}

let sizingString = """
President Trump’s $1.5 trillion tax cut was supposed to be a big selling point for congressional Republicans in the midterm elections. Instead, it appears to have done more to hurt, than help, Republicans in high-tax districts across California, New Jersey, Virginia and other states.

House Republicans suffered heavy Election Day losses in districts where large concentrations of taxpayers claim a popular tax break — the state and local tax deduction — which the law capped at $10,000 per household. The new limit resulted in an effective tax increase for high-earning residents of high-tax states who claim more than $10,000 per year in SALT.

Democrats swept four Republican-held districts in Orange County, Calif., where at least 40 percent of taxpayers claim the SALT tax break, defeating a pair of Republican incumbents and winning seats vacated by Representatives Ed Royce and Darrell Issa. Those districts include longtime Republican strongholds, like Newport Beach, and rank among the country’s largest users of the state and local tax break.
"""
