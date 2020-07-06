//
//  ArticleViewController.swift
//  Scroll Data
//
//  Created by Arman Aydemir on 3/31/18.
//  Copyright © 2018 Arman Aydemir. All rights reserved.
//

import UIKit
import Foundation

@objc class ArticleViewController: UIViewController {
    var data: [String:Any]  = [:]
    var content: Array<Content> = []
    var vm: ArticleViewModel! = nil
    let time_offset = 100000000.0
    var articleLink: String?
    
    var complete = false
    var content_offset:CGFloat?
    
    var font: UIFont = UIFont.init(name: "Times New Roman", size: UIFont.systemFontSize) ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
    let titleFont = SystemFont.init(fontName: "Times New Roman")?.getFont(withTextStyle: .title1) ?? UIFont.preferredFont(forTextStyle: .title1)
    
    
    @IBOutlet weak var imageView: UIImageView!
    var contentTopOffsets: [CGFloat] = []
    var contentBottomOffsets: [CGFloat] = []
    
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
            print("woahipad")
            print(view.readableContentGuide.trailingAnchor.description)
            print(view.readableContentGuide.leadingAnchor.description)
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
//        imageView.isHidden = true
        vm.fetchText(completion: { data, error in
            DispatchQueue.main.async {
                self.data = data
                
                
//                self.font = self.findFontSize(table: table) ?? UIFont.preferredFont(forTextStyle: .body)
//                let content = self.convert(paragraphs: p, font: self.font)
                
                //render as rendered on recorded device
                let content = self.convertSession(data: data)
                self.font =  self.findSessionFontSize(table: table, c: content, data: data) ?? UIFont.preferredFont(forTextStyle: .body)
                self.content = content
                
                table.reloadData()
                self.spinner?.stopAnimating()
                table.isHidden = false
                print(table.numberOfRows(inSection: 0))
                print(content.count)
                DispatchQueue.main.asyncAfter(deadline: .now()+1) {

                    self.collectContentOffsets(table: table)
                    let image = self.asFullImage(table: table)!
                    let imageView = UIImageView(image: image)
                    print(image)
                    
                   
                    self.view.addSubview(imageView)
                    NSLayoutConstraint.activate([
                        imageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor)
                    ])
                    self.view.layoutIfNeeded()
                    imageView.layoutIfNeeded()
                    self.view.bringSubviewToFront(imageView)
                    table.isHidden = true
                    self.view.backgroundColor = UIColor.white
                    self.view.superview?.backgroundColor = UIColor.white
                    imageView.backgroundColor = UIColor.white
                    self.startAutoScroll(imageView: imageView, data: data)
                }
            }
        })
    }
    
    //MARK: - Add image to Library
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        let lines = self.content.filter { return !$0.spacer }
        let wordIndices = lines.map { $0.firstWordIndex }
        let characterIndices = lines.map { $0.firstCharacterIndex }
        
        self.vm.closeArticle(content: self.content.map { $0.toDictionary() }, wordIndicies: wordIndices, characterIndicies: characterIndices, complete: self.complete)
        
        guard let a = UIApplication.shared.delegate as? AppDelegate else {return}
        a.autoRotate = true
    }
    
    
    func startAutoScroll(imageView: UIView, data: [String:Any]) {
        let s = self.data["session_data"] as! Array<[String:Any]>
        let time_key = "appeared"
        let key = "scrollAnim"
        let stime = Double(s[0]["startTime"] as! NSNumber)/self.time_offset
//        let diffH = viewableAreaHeight(showOnBottom: true) - viewableAreaHeight(showOnBottom: false)
        let offset_val = self.view.safeAreaInsets.bottom + self.view.safeAreaInsets.top
        let anim = CAKeyframeAnimation(keyPath: "position.y")
        var anim_vals: [CGFloat] = []
        var anim_keyTimes: [NSNumber] = []
        
//        anim.duration = (Double(s.last![time_key] as! NSNumber)/self.time_offset)-stime
        anim.duration = 10 + (Double(s.last![time_key] as! NSNumber)/self.time_offset)-stime
        //        let tsize = table.rect(forSection: 0).size
        //        let height_per_line = (tsize.height-screenH) / CGFloat.init(exactly: s.count-2)!
        
        var i = 0
        while(i < s.count){
            let t1  = Double(s[i][time_key] as! NSNumber)/self.time_offset
            
            let last_cell = Double(s[i]["last_cell"] as! NSNumber)
            let first_cell = Double(s[i]["first_cell"] as! NSNumber)
            
            if(Int(last_cell) > self.content.count - 2){
                let c = data["content"] as! Array<[String:Any]>
                let first_percen = (first_cell/Double(c.count))*Double(self.content.count)
                let tottemp = -self.contentTopOffsets[Int(first_percen)]
                
                anim_vals.append(offset_val + tottemp)
            }else if(first_cell <= 1){
                let c = data["content"] as! Array<[String:Any]>
                let last_percen = (last_cell/Double(c.count))*Double(self.content.count)
                let tottemp = -self.contentBottomOffsets[Int(last_percen)]
                
                anim_vals.append(offset_val + tottemp)
            }else{
                let c = data["content"] as! Array<[String:Any]>
                let first_percen = (first_cell/Double(c.count))*Double(self.content.count)
                let last_percen = (last_cell/Double(c.count))*Double(self.content.count)
                let tottemp = (-self.contentTopOffsets[Int(first_percen)] - self.contentBottomOffsets[Int(last_percen)])/2
                
                anim_vals.append(offset_val + tottemp)
            }
            anim_keyTimes.append(NSNumber(value: (5 + t1-stime)/anim.duration))
//            anim_keyTimes.append(NSNumber(value: (t1-stime)/anim.duration))
            i += 1
        }
        anim.values = anim_vals
        anim.keyTimes = anim_keyTimes
        anim.isAdditive = true

        imageView.superview?.layer.add(anim, forKey: key)
        
    }
    
    func collectContentOffsets(table:UITableView) {
        guard table.numberOfSections > 0, table.numberOfRows(inSection: 0) > 0 else {
            return
        }
        for section in 0..<table.numberOfSections {
            for row in 0..<table.numberOfRows(inSection: section) {
                table.scrollToRow(at: IndexPath(row: row, section: section), at: .bottom, animated: false)
                self.contentBottomOffsets.append(table.contentOffset.y)
                table.scrollToRow(at: IndexPath(row: row, section: section), at: .top, animated: false)
                self.contentTopOffsets.append(table.contentOffset.y)
            }
        }
    }
    
    func findFontSize(table:UITableView) -> UIFont? {
        let string = sizingString
        let height = viewableAreaHeight(showOnBottom: false)
        let size = CGSize.init(width: table.frame.width-ArticleTextTableViewCell.widthSpacingConstant*2, height: height)
        let ff = SystemFont.init(fontName: "Times New Roman")?.fontToFit(text: string, inSize: size, spacing: ArticleTextTableViewCell.topSpacingConstant*2)
        return ff
    }
    
    func findSessionFontSize(table:UITableView, c: [Content], data: [String:Any]) -> UIFont? {
        var i = 1
        var fonts: [UIFont?] = []
        while(i < c.count - 1){
            if(c[i].text != ""){
                let height = viewableAreaHeight(showOnBottom: false)
                let size = CGSize.init(width: table.frame.width-ArticleTextTableViewCell.widthSpacingConstant*2, height: height)
                fonts.append(SystemFont.init(fontName: "Times New Roman")?.fontToFitLine(text: c[i].text, inSize: size, spacing: ArticleTextTableViewCell.topSpacingConstant*2))
            }
            i = i + 1
            
        }
        i = 0
        var smallestFont = fonts[0]
        while(i < fonts.count){
            if(smallestFont!.pointSize > fonts[i]!.pointSize){
                smallestFont = fonts[i]
            }
            i = i + 1
        }
        return smallestFont
    }
    
    func cellFit(string:String, attributes: [NSAttributedString.Key: Any]) -> Bool {
        guard let checker = self.minTableDim else {
            //print("not table exists, this should never happen")
            print("error in cellFit")
            return false
        }
        
        return (string as NSString).size(withAttributes: attributes).width < checker - ArticleTextTableViewCell.widthSpacingConstant*2
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

    
//    @objc func willResignActive(_ notification: Notification) {
//        _ = navigationController?.popViewController(animated: true)
//    }
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
                cell.submitButton.titleLabel?.textColor = UIColor.black
                cell.textLabel?.textColor = UIColor.black
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
                    cell.titleText.textColor = UIColor.black
                    cell.textLabel?.textColor = UIColor.black
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
                    cell.textSection.textColor = UIColor.black
                    cell.textSection.adjustsFontSizeToFitWidth = true
                    cell.textLabel?.textColor = UIColor.black
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

extension ArticleViewController {
    func convertSession(data: [String:Any]) -> [Content] {
        var cells = [Content].init()
        let c = data["content"] as! Array<[String:Any]>
        var i = 0
        while(i < c.count){
            cells.append(Content.init(text:  c[i]["text"] as! String, paragraph: c[i]["paragraph"] as! Int, firstWordIndex: c[i]["first_word_index"] as! Int, firstCharacterIndex: c[i]["first_character_index"] as! Int, spacer: (c[i]["spacer"] != nil)))
            i = i + 1
        }
        return cells
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
    
    func asFullImage(table:UITableView) -> UIImage? {
        guard table.numberOfSections > 0, table.numberOfRows(inSection: 0) > 0 else {
            return nil
        }
        print(table.isHidden)
        table.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        var height: CGFloat = 0.0
        var counter = 0
        for section in 0..<table.numberOfSections {
            var cellHeight: CGFloat = 0.0
            for row in 0..<table.numberOfRows(inSection: section) {
                let indexPath = IndexPath(row: row, section: section)
                counter += 1
                guard let cell = table.cellForRow(at: indexPath) else { continue }
                cellHeight = cell.frame.size.height
            }
            height += cellHeight * CGFloat(table.numberOfRows(inSection: section))
        }
        print(counter)
        UIGraphicsBeginImageContextWithOptions(CGSize(width: table.contentSize.width, height: height), false, UIScreen.main.scale)

        for section in 0..<table.numberOfSections {
            for row in 0..<table.numberOfRows(inSection: section) {
                let indexPath = IndexPath(row: row, section: section)
                guard let cell = table.cellForRow(at: indexPath) else { continue }
                cell.contentView.drawHierarchy(in: cell.frame, afterScreenUpdates: true)

                if row < table.numberOfRows(inSection: section) - 1 {
                    table.scrollToRow(at: IndexPath(row: row+1, section: section), at: .bottom, animated: false)
                }
            }
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
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
            "spacer" : spacer,
        ]
    }
}


let sizingString = """
President Trump’s $1.5 trillion tax cut was supposed to be a big selling point for congressional Republicans in the midterm elections. Instead, it appears to have done more to hurt, than help, Republicans in high-tax districts across California, New Jersey, Virginia and other states.

House Republicans suffered heavy Election Day losses in districts where large concentrations of taxpayers claim a popular tax break — the state and local tax deduction — which the law capped at $10,000 per household. The new limit resulted in an effective tax increase for high-earning residents of high-tax states who claim more than $10,000 per year in SALT.

Democrats swept four Republican-held districts in Orange County, Calif., where at least 40 percent of taxpayers claim the SALT tax break, defeating a pair of Republican incumbents and winning seats vacated by Representatives Ed Royce and Darrell Issa. Those districts include longtime Republican strongholds, like Newport Beach, and rank among the country’s largest users of the state and local tax break.
"""
