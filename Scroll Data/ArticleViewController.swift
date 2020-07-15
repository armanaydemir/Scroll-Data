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
    let replay = false
    var data: [String:Any]  = [:]
    var content: Array<Content> = []
    var vm: ArticleViewModel! = nil
    let time_offset = 100000000.0
    var articleLink: String?
    
    let timePerCheck = 0.00001
    var timer: Timer? = nil
    
    var image = UIImage.init(named: "test")
    
    var complete = false
    var content_offset:CGFloat?
    
    var font: UIFont = UIFont.init(name: "Times New Roman", size: UIFont.systemFontSize) ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
    let titleFont = SystemFont.init(fontName: "Times New Roman")?.getFont(withTextStyle: .title1) ?? UIFont.preferredFont(forTextStyle: .title1)
    
    var contentTopOffsets: [CGFloat] = []
    var contentBottomOffsets: [CGFloat] = []
    var maxLinesOnScreen = 20.0
    
    var minTableDim:CGFloat?
    
    @IBOutlet weak var table: UITableView?
    @IBOutlet weak var spinner: UIActivityIndicatorView?
    @IBOutlet weak var hardTableView: HardTableView!
    
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
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 68.0
        spinner.hidesWhenStopped = true
        spinner.startAnimating()
        
        let model = UIDevice.current.model.lowercased()
        if(model.contains("ipad")){
            print("ipad")
            NSLayoutConstraint.activate([
                table.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
                table.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
                ])
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        guard let table = self.table else {
            print("couldn't connect outlets! bad things coming.....")
            return
        }
 
        table.backgroundColor = UIColor.white
        self.view.backgroundColor = UIColor.white
        self.view.superview?.backgroundColor = UIColor.white

        DispatchQueue.main.async {
            self.minTableDim = min(table.frame.size.width, table.frame.size.height)
        }
        
        vm.fetchText(completion: { data, error in
            DispatchQueue.main.async {
                self.data = data
                
                //render as rendered on recorded device
                self.maxLinesOnScreen = data["max_lines"] as! Double
        
                let dataList = (data["content"] as? [Any])?.compactMap { try? Content(data: $0) }
                guard let contentList = dataList else { return }
                
                self.view.layoutIfNeeded()
                
                self.font =  self.findSessionFontSize(table: table, c: contentList, data: data) ?? UIFont.preferredFont(forTextStyle: .body)
                self.content = contentList
                
                table.reloadData()
                self.spinner?.stopAnimating()
                
                table.isHidden = true
                self.loadHardTableView()
                if(self.replay){
                    DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                        self.startAutoScrolling()
                    }
                }else{
                    DispatchQueue.main.asyncAfter(deadline: .now()){
                        self.repeatingCheck()
                    }
                }
            }
        })
    }
    
    func loadHardTableView() {
        
        let maxVisibleLines = self.maxLinesOnScreen //TODO: should come from server
        
        let normalLineLabelHeight: CGFloat = hardTableView.frame.size.height / CGFloat(maxVisibleLines)
        let titleLabelHeight: CGFloat = hardTableView.frame.size.height
        
        let cells: [HardTableView.Cell] = self.content.enumerated().map { index, content in
            
            let label = UILabel(frame: CGRect.zero)
            label.text = content.text
            label.translatesAutoresizingMaskIntoConstraints = false
            
            switch index {
            case 0:
                label.numberOfLines = 0
                label.font = self.titleFont
                label.textAlignment = .center
                return HardTableView.Cell(view: label, height: titleLabelHeight)
            default:
                label.font = self.font
                label.textAlignment = .justified
                return HardTableView.Cell(view: label, height: normalLineLabelHeight)
            }
        }
        
        hardTableView.cells = cells
        hardTableView.backgroundColor = UIColor.purple
    }
    
    func startAutoScrolling() {
        guard let session = try? Session(data: self.data) else { return }
        
        let totalDuration = session.endTime - session.startTime
        
        let keyFrames: (() -> Void) = {
            session.relativePageStates.sorted { $0.relativeStartTime < $1.relativeStartTime }.forEach { pageState in
                
                print("\(pageState.firstLine), \(pageState.relativeStartTime * totalDuration), \(pageState.relativeDuration * totalDuration), \(pageState.contentOffset)")

                UIView.addKeyframe(withRelativeStartTime: pageState.relativeStartTime, relativeDuration: pageState.relativeDuration) {
                    
                    self.hardTableView.scrollToRow(index: pageState.firstLine, position: .top, animated: false)
//                    self.hardTableView.contentOffset = CGPoint(x: CGFloat(0), y: pageState.contentOffset)
                    
                    print("visible cells: \(self.hardTableView.visibleIndices())")
                }
            }
        }
        
        UIView.animateKeyframes(withDuration: totalDuration,
                                delay: 0,
                                options: [.beginFromCurrentState],
                                animations: keyFrames,
                                completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        let lines = self.content.filter { return !$0.spacer }
        let wordIndices = lines.map { $0.firstWordIndex }
        let characterIndices = lines.map { $0.firstCharacterIndex }
        
        self.vm.closeArticle(content: self.content.map { $0.toDictionary() }, wordIndicies: wordIndices, characterIndicies: characterIndices, complete: self.complete)
        
        guard let a = UIApplication.shared.delegate as? AppDelegate else {return}
        a.autoRotate = true
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
    
//    func findFontSize(table:UITableView) -> UIFont? {
//        let string = sizingString
//        let height = viewableAreaHeight(showOnBottom: false)
//        let size = CGSize.init(width: table.frame.width-ArticleTextTableViewCell.widthSpacingConstant*2, height: height)
//        let ff = SystemFont.init(fontName: "Times New Roman")?.fontToFit(text: string, inSize: size, spacing: ArticleTextTableViewCell.topSpacingConstant*2)
//        return ff
//    }
    
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
    
    func repeatingCheck() {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.timer = Timer.init(timeInterval: self.timePerCheck, repeats: true, block: { _ in
                self.sendTextToServer()
            })
            RunLoop.main.add(self.timer!, forMode: RunLoop.Mode.common)
            self.spinner?.stopAnimating()
            self.sendTextToServer()
        }
    }

    
    func sendTextToServer() -> Void {
//        let current_offset = tableView.contentOffset.y
//
//        guard current_offset != self.content_offset && !tableView.isHidden
//            else {
//                print("table not visible or no content offset change")
//                return
//        }
//
//        guard let first = tableView.visibleCells.first,
//            let first_index = tableView.indexPath(for: first)?.item,
//            let second = tableView.visibleCells.last,
//            let last_index = tableView.indexPath(for: second)?.item
//            else {
//                print("no visible cells")
//                return
//        }
        print(self.hardTableView.visibleIndices())
        //vm.submitData(content_offset: current_offset, first_index: first_index, last_index: last_index)
    }

    
//    @objc func willResignActive(_ notification: Notification) {
//        _ = navigationController?.popViewController(animated: true)
//    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination
        if let destination:DisplayViewController = vc as? DisplayViewController {
            destination.data = self.data
            destination.contentBottomOffsets = self.contentBottomOffsets
            destination.contentTopOffsets = self.contentTopOffsets
            destination.content = self.content
            destination.image = self.image
            guard let a = UIApplication.shared.delegate as? AppDelegate else {return}
            a.autoRotate = false
            a.orientation = UIDevice.current.orientation
        }
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
                cell.backgroundColor = UIColor.white
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
                    cell.backgroundColor = UIColor.white
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
                    cell.backgroundColor = UIColor.white
                    //cell.textSection.adjustsFontSizeToFitWidth = true
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


let sizingString = """
President Trump’s $1.5 trillion tax cut was supposed to be a big selling point for congressional Republicans in the midterm elections. Instead, it appears to have done more to hurt, than help, Republicans in high-tax districts across California, New Jersey, Virginia and other states.

House Republicans suffered heavy Election Day losses in districts where large concentrations of taxpayers claim a popular tax break — the state and local tax deduction — which the law capped at $10,000 per household. The new limit resulted in an effective tax increase for high-earning residents of high-tax states who claim more than $10,000 per year in SALT.

Democrats swept four Republican-held districts in Orange County, Calif., where at least 40 percent of taxpayers claim the SALT tax break, defeating a pair of Republican incumbents and winning seats vacated by Representatives Ed Royce and Darrell Issa. Those districts include longtime Republican strongholds, like Newport Beach, and rank among the country’s largest users of the state and local tax break.
"""
