//
//  ArticleViewController.swift
//  Scroll Data
//
//  Created by Arman Aydemir on 3/31/18.
//  Copyright © 2018 Arman Aydemir. All rights reserved.
//

import UIKit


@objc class ArticleViewController: UIViewController {
    
    var content: Array<Content> = []
    var articleLink: String?
    var vm: ArticleViewModel! = nil
    var complete = false
    
    let paragraphStyle = NSMutableParagraphStyle()
    
    var font: UIFont = UIFont.init(name: "Times New Roman", size: UIFont.systemFontSize) ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
    let titleFont = SystemFont.init(fontName: "Times New Roman")?.getFont(withTextStyle: .title1) ?? UIFont.preferredFont(forTextStyle: .title1)
    var content_offset:CGFloat?
   
    let timePerCheck = 0.00001
    
    var minTableDim:CGFloat?
    
    @IBOutlet weak var table: UITableView?
    @IBOutlet weak var spinner: UIActivityIndicatorView?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let table = self.table, let spinner = self.spinner else {
            print("couldn't connect outlets! bad things coming.....")
            return
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: .UIApplicationWillResignActive, object: nil)
        
        vm = ArticleViewModel.init(articleLink: self.articleLink!)
        
        table.isHidden = true;
        table.accessibilityIdentifier = "articleTable"
        table.separatorStyle = UITableViewCellSeparatorStyle.none
        table.dataSource = self
        table.register(UINib.init(nibName: "ArticleTextTableViewCell", bundle: nil), forCellReuseIdentifier: "default")
        table.register(UINib.init(nibName: "TitleCellTableViewCell", bundle: nil), forCellReuseIdentifier: "title")
        table.register(UINib.init(nibName: "SubmitTableViewCell", bundle: nil), forCellReuseIdentifier: "submit")
        table.delegate = self
        table.cellLayoutMarginsFollowReadableWidth = false
        table.estimatedRowHeight = 68.0
        table.rowHeight = UITableViewAutomaticDimension

        spinner.hidesWhenStopped = true
        spinner.startAnimating()
        
//        let model = UIDevice.current.model
//        if(model == "iPad"){
//            //            NSLayoutConstraint.activate([
//            //                table.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
//            //                table.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
//            //                table.bottomAnchor.constraint(equalTo: view.readableContentGuide.bottomAnchor),
//            //                table.topAnchor.constraint(equalTo: view.readableContentGuide.topAnchor)
//            //                ])
//            self.view.layoutIfNeeded()
//        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        guard let table = self.table else {
            print("couldn't connect outlets! bad things coming.....")
            return
        }

        DispatchQueue.main.async {
            self.minTableDim = min(table.frame.size.width, table.frame.size.height)
        }
        
        vm.fetchText(completion: { paragraphs, error in
            guard let p = paragraphs else {
                let alert = UIAlertController.init(title: "error fetching text", message: error, preferredStyle: UIAlertControllerStyle.alert)
                self.present(alert, animated: true, completion: nil)
                return
            }
            DispatchQueue.main.async {
                self.font = self.findFontSize(table: table) ?? UIFont.preferredFont(forTextStyle: .body)
                let content = self.convert(paragraphs: p, font: self.font)
                self.content = content

                table.reloadData()
                
                self.repeatingCheck(table: table)
            }
        })
    }
    
    func repeatingCheck(table: UITableView) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(2000)) {
            let timer = Timer.init(timeInterval: self.timePerCheck, repeats: true, block: { _ in
                self.sendTextToServer(tableView: table)
            })
            RunLoop.main.add(timer, forMode: RunLoopMode.commonModes)
            self.spinner?.stopAnimating()
            table.isHidden = false
            self.sendTextToServer(tableView: table)
        }
    }
    
    func findFontSize(table:UITableView) -> UIFont? {
        let string = sizingString
        let height = (UIScreen.main.bounds.height-(self.view.safeAreaInsets.top + self.view.safeAreaInsets.bottom))
        let size = CGSize.init(width: table.frame.width-ArticleTextTableViewCell.widthSpacingConstant*2, height: height)
        return SystemFont.init(fontName: "Times New Roman")?.fontToFit(text: string, inSize: size, spacing: ArticleTextTableViewCell.topSpacingConstant*2)
    }
    
    func currentPosition(tableView:UITableView) -> Array<Int> {

        let first_index = tableView.indexPath(for: tableView.visibleCells.first!)?.item
        let second_index = tableView.indexPath(for: tableView.visibleCells.last!)?.item
        
        return [first_index!, second_index!]
    }
    
    func sendTextToServer(tableView:UITableView) -> Void {
        //print("send text - \(CFAbsoluteTimeGetCurrent())")
        let current_offset = tableView.contentOffset.y
        if tableView.isHidden || current_offset == self.content_offset { return }
        
        let temp = currentPosition(tableView: tableView)
        let first_index = temp[0], last_index = temp[1]
            
        vm.submitData(content_offset: current_offset, first_index: first_index, last_index: last_index)
        
    }
    
    func cellFit(string:String, attributes:[String: Any]) -> Bool {
        guard let checker = self.minTableDim else {
            //print("not table exists, this should never happen")
            print("error in cellFit")
            return false
        }
        
        return (string as NSString).size(attributes: attributes).width < checker - ArticleTextTableViewCell.widthSpacingConstant*2
    }
    

    
    @objc func willResignActive(_ notification: Notification) {
        _ = navigationController?.popViewController(animated: true)
    }
    
    func convert(paragraphs: [String], font: UIFont) -> [Content] {
        var cells = [Content].init()
        var p = 0
        var word_count = 0
        var char_count = 0
        let attributes = [NSFontAttributeName: font] as [String : Any]
        cells.append(Line.init(text: paragraphs[0], paragraph: p, firstWordIndex: word_count, firstCharacterIndex: char_count))
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
                cells.append(Line.init(text: current_text, paragraph: p, firstWordIndex: word_count, firstCharacterIndex: char_count))

            }
            p += 1
            cells.append(Spacer())
        }
        return cells
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
                cell.submitButton.setTitle("Tap to submit data", for: UIControlState.normal)
                cell.selectionStyle = .none
                cell.isSelected = false
                cell.accessibilityLabel = "submitCell"
            }
            return cell
        }else{
            let aString = self.content[indexPath.item].getText()
            if(indexPath.item == 0){
                let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "title", for: indexPath)
                if let cell: TitleCellTableViewCell = cell as? TitleCellTableViewCell {
                    let attributes = [NSFontAttributeName: self.titleFont] as [String : Any]
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
                    let attributes = [NSFontAttributeName: font] as [String : Any]
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
            return UIScreen.main.bounds.size.height - (self.navigationController?.navigationBar.frame.size.height ?? 0) - 1
        case (self.content.count):
            return UIScreen.main.bounds.size.height - (self.navigationController?.navigationBar.frame.size.height ?? 0) - 1
        default:
            return UITableViewAutomaticDimension
        }
    }
}

protocol Content {
    func isSpacer() -> Bool
    func getText() -> String
}

struct Line: Content  {
    
    let text: String
    let paragraph: Int
    let firstWordIndex: Int
    let firstCharacterIndex: Int
    
    func isSpacer() -> Bool {
        return false
    }
    
    func getText() -> String {
        return text
    }
}

struct Spacer: Content {
    func isSpacer() -> Bool {
        return true
    }
    
    func getText() -> String{
        return ""
    }
}

let sizingString = """
President Trump’s $1.5 trillion tax cut was supposed to be a big selling point for congressional Republicans in the midterm elections. Instead, it appears to have done more to hurt, than help, Republicans in high-tax districts across California, New Jersey, Virginia and other states.

House Republicans suffered heavy Election Day losses in districts where large concentrations of taxpayers claim a popular tax break — the state and local tax deduction — which the law capped at $10,000 per household. The new limit resulted in an effective tax increase for high-earning residents of high-tax states who claim more than $10,000 per year in SALT.

Democrats swept four Republican-held districts in Orange County, Calif., where at least 40 percent of taxpayers claim the SALT tax break, defeating a pair of Republican incumbents and winning seats vacated by Representatives Ed Royce and Darrell Issa. Those districts include longtime Republican strongholds, like Newport Beach, and rank among the country’s largest users of the state and local tax break.
"""
