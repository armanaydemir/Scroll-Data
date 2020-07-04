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
    //let scroll_type = "exact" //"scroll_every_x"
    let scroll_type = "exact"
    var content: Array<Content> = []
    var articleLink: String?
    var vm: ArticleViewModel! = nil
    var complete = false
    var scrollOffset = 0.0
    var time_offset = 100000000.0
    var data: [String:Any]  = [:]
    var contentTopOffsets: [CGFloat] = []
    var contentBottomOffsets: [CGFloat] = []
    var tableH: CGFloat = 0.0
    
    let paragraphStyle = NSMutableParagraphStyle()
    
    var font: UIFont = UIFont.init(name: "Times New Roman", size: UIFont.systemFontSize) ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
    let titleFont = SystemFont.init(fontName: "Times New Roman")?.getFont(withTextStyle: .title1) ?? UIFont.preferredFont(forTextStyle: .title1)
    var content_offset:CGFloat?
   
    let timePerCheck = 0.00001
    let timePerScroll = 0.001
    var lastTime = CFAbsoluteTimeGetCurrent()
    let timeBetweenScroll = 4.0
    var timer: Timer? = nil
    
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
        
        vm.fetchText(completion: { data, error in
            guard case let p as [String] = data["paragraphs"] else {
                let alert = UIAlertController.init(title: "error fetching text", message: error, preferredStyle: UIAlertController.Style.alert)
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            DispatchQueue.main.async {
                self.data = data
                self.font = self.findFontSize(table: table) ?? UIFont.preferredFont(forTextStyle: .body)
                //let content = self.convert(paragraphs: p, font: self.font)
                let content = self.convertSession(font: self.font)
                self.content = content
                
                
                guard case var s as Array<[String:Any]> = self.data["session_data"] else {
                    let alert = UIAlertController.init(title: "error fetching session data", message: nil, preferredStyle: UIAlertController.Style.alert)
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                
                //print(s[1])
                table.reloadData()
                self.spinner?.stopAnimating()
                table.isHidden = false
                
                print(table.rectForRow(at: IndexPath.init(row: 1, section: 0)).size)
                print(table.rect(forSection: 0).size)
                UIGraphicsBeginImageContext(table.rect(forSection: 0).size)
                table.dragInteractionEnabled = false //true make sure to remember this
//                let t1 = Int(s[0]["time"] as! NSNumber)
                self.collectContentOffsets(table: table)
                let image = self.asFullImage(table: table)
                
                print(image)
                
                let imageView = UIImageView(image: image!)
                imageView.translatesAutoresizingMaskIntoConstraints = false
//                imageView.contentMode = UIView;
//                imageView.frame = table.rect(forSection: 0)
   
                self.view.addSubview(imageView)
                NSLayoutConstraint.activate([
                    imageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor)
                ])
                self.view.layoutIfNeeded()
                imageView.layoutIfNeeded()
                self.view.bringSubviewToFront(imageView)
                table.isHidden = true
                self.view.backgroundColor = UIColor.white
                imageView.backgroundColor = UIColor.white
                //UIGraphicsEndImageContext()
                self.startAutoScroll(imageView: imageView, s: s)
                //self.scrollEventTrigger(table: table, s:s, last_time:t1 ,scrollIndex:1)
            }
        })
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
    
    override func viewWillDisappear(_ animated: Bool) {
        let lines = self.content.filter { return !$0.spacer }
        let wordIndices = lines.map { $0.firstWordIndex }
        let characterIndices = lines.map { $0.firstCharacterIndex }
        
        self.timer?.invalidate()
        
        self.vm.closeArticle(content: self.content.map { $0.toDictionary() }, wordIndicies: wordIndices, characterIndicies: characterIndices, complete: self.complete)
        
        guard let a = UIApplication.shared.delegate as? AppDelegate else {return}
        a.autoRotate = true
    }
    
    
    func startAutoScroll(imageView: UIView, s:Array<[String:Any]>) {
        guard let table = table else { return }
        let time_key = "appeared"
        let key = "scrollAnim"
        let stime = Double(s[0]["startTime"] as! NSNumber)/self.time_offset
        let tsize = table.rect(forSection: 0).size
        let screenH = -viewableAreaHeight(showOnBottom: false)
        let tableH = table.frame.height
        self.tableH = tableH
        let diffH = screenH + tableH
        let offset_val = -diffH
        let height_per_line = (tsize.height-screenH) / CGFloat.init(exactly: s.count-2)!
        var i = 0
        //var anims: [CAKeyframeAnimation] = []
        let anim = CAKeyframeAnimation(keyPath: "position.y")
        var anim_vals: [CGFloat] = []
        var anim_keyTimes: [NSNumber] = []
        var llcell = -1
        var ffcell = -1
        anim.duration = (Double(s.last![time_key] as! NSNumber)/self.time_offset)-stime
        while(i < s.count){
            let t1  = Double(s[i][time_key] as! NSNumber)/self.time_offset
            //let t2 = Double(s[i+1]["time"] as! NSNumber)
            let last_cell = Double(s[i]["last_cell"] as! NSNumber)
            let first_cell = Double(s[i]["first_cell"] as! NSNumber)
            //anim.fromValue = CGFloat.init(exactly: height_per_line)
            //anim.toValue = CGFloat.init(exactly: fvalue)
            //anim.fromValue = fvalue
            //anim.toValue = -(height_per_line*CGFloat(last_cell)) +  imageView.frame.origin.y + offset_val
//            if(llcell != last_cell){
//                if(last_cell == 1){
//                    print(-(height_per_line*CGFloat(last_cell)) + imageView.frame.origin.y + offset_val)
//                    print(-(s[i]["content_offset"] as! CGFloat) + offset_val)
//                }
            print(self.contentTopOffsets.count)
            print(s.count)
            if(Int(last_cell) - self.content.count >= -1){
                let c = self.data["content"] as! Array<[String:Any]>
                let first_percen = (first_cell/Double(c.count))*Double(self.content.count)
                let ccount = c.count
                let contcount = self.content.count

                let tottemp = -self.contentTopOffsets[Int(first_percen)]
                anim_vals.append(offset_val + tottemp)
            }else if(first_cell <= 1){
                let c = self.data["content"] as! Array<[String:Any]>
                let last_percen = (last_cell/Double(c.count))*Double(self.content.count)
                let ccount = c.count
                let contcount = self.content.count

                let tottemp = -self.contentBottomOffsets[Int(last_percen)]
                anim_vals.append(offset_val + tottemp)
            }else{
                let c = self.data["content"] as! Array<[String:Any]>
                let first_percen = (first_cell/Double(c.count))*Double(self.content.count)
                let last_percen = (last_cell/Double(c.count))*Double(self.content.count)
                let ccount = c.count
                let contcount = self.content.count

                let tottemp = (-self.contentTopOffsets[Int(first_percen)] - self.contentBottomOffsets[Int(last_percen)])/2
                anim_vals.append(offset_val + tottemp)
            }
            //anim_vals.append(-self.contentBottomOffsets[last_cell])
            anim_keyTimes.append(NSNumber(value: (t1-stime)/anim.duration))
                
//                print("last")
//                print(offset_val)
//            }
//            else if(ffcell != first_cell){
//                anim_vals.append(-self.contentTopOffsets[first_cell])
//                anim_keyTimes.append(NSNumber(value: (t1-stime)/anim.duration))
//            }
//            print(-(s[i]["content_offset"] as! CGFloat) + offset_val)
//            print(anim_vals.last)
//            print("-----------")
            llcell = Int(last_cell)
            ffcell = Int(first_cell)
            //anim_vals.append(-(s[i]["content_offset"] as! CGFloat) + offset_val)
            //fvalue = anim.toValue as! CGFloat
           
            //anim.duration = 5.0
            //tot_dur += CFTimeInterval(Double(t2-t1)/self.time_offset)
            i += 1
        }
        anim.values = anim_vals
        anim.keyTimes = anim_keyTimes
        anim.isAdditive = true
//        anim.calculationMode = CAAnimationCalculationMode.linear
//        anim.calculationMode = CAAnimationCalculationMode.cubic
        // anim.calculationMode = CAAnimationCalculationMode.discrete
//        print(anim.beginTime)
        print(anim.values)
//        print(anim.keyTimes)
//        print(anim.duration)
//        print("----")
        imageView.superview?.layer.add(anim, forKey: key)
        
//        DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
//            i = 0
//            while(i < anims.count){
//                imageView.layer.add(anims[i], forKey: nil)
//                i += 1
//            }
//        })
//
        
        
//        var m = CGAffineTransform.init(translationX: 0, y: 200)
//        table.layer.setAffineTransform(m)
//        table.layer.affineTransform()
//
//        m = CGAffineTransform.init(translationX: 50, y: 0)
//        table.layer.setAffineTransform(m)
//        table.layer.affineTransform()
        
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
    
    func findFontSize(table:UITableView) -> UIFont? {
        let string = sizingString
        let height = viewableAreaHeight(showOnBottom: false)
        let size = CGSize.init(width: table.frame.width-ArticleTextTableViewCell.widthSpacingConstant*2, height: height)
        return SystemFont.init(fontName: "Times New Roman")?.fontToFit(text: string, inSize: size, spacing: ArticleTextTableViewCell.topSpacingConstant*2)
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
    
    func convertSession(font : UIFont) -> [Content] {
        var cells = [Content].init()
        let c = self.data["content"] as! Array<[String:Any]>
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
    func asFullImage(table:UITableView) -> UIImage? {
        guard table.numberOfSections > 0, table.numberOfRows(inSection: 0) > 0 else {
            return nil
        }

        table.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        var height: CGFloat = 0.0
        for section in 0..<table.numberOfSections {
            var cellHeight: CGFloat = 0.0
            for row in 0..<table.numberOfRows(inSection: section) {
                let indexPath = IndexPath(row: row, section: section)
                guard let cell = table.cellForRow(at: indexPath) else { continue }
                cellHeight = cell.frame.size.height
            }
            height += cellHeight * CGFloat(table.numberOfRows(inSection: section))
        }

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

        return image!
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
