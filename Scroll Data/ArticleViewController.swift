//
//  ArticleViewController.swift
//  Scroll Data
//
//  Created by Arman Aydemir on 3/31/18.
//  Copyright © 2018 Arman Aydemir. All rights reserved.
//

import UIKit

@objc class ArticleViewController: UIViewController {
    let replay = true
    
    var vm: ArticleViewModel! = nil
    var articleLink: String?
    
    let timePerCheck = 0.00001
    var timer: Timer? = nil
    
    var image = UIImage.init(named: "test")
    
    var font: UIFont = UIFont.init(name: "Times New Roman", size: UIFont.systemFontSize) ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
    let titleFont = SystemFont.init(fontName: "Times New Roman")?.getFont(withTextStyle: .title1) ?? UIFont.preferredFont(forTextStyle: .title1)
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var hardTableView: HardTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        
        vm = ArticleViewModel.init(articleLink: self.articleLink!)
        spinner.hidesWhenStopped = true
        spinner.startAnimating()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        vm.fetchText(completion: { result in
            switch result {
            case .success(let sessionReplay):
                self.useSessionReplay(sessionReplay: sessionReplay)
            case .failure(let error):
                print(error)
            }
            
        })
    }
    
    func useSessionReplay(sessionReplay: SessionReplayResponse) {
        DispatchQueue.main.async {
            
            self.view.layoutIfNeeded()
            
//            self.font =  self.findSessionFontSize(table: table, c: contentList, data: data) ?? UIFont.preferredFont(forTextStyle: .body)
            
            self.spinner?.stopAnimating()
            self.loadHardTableView(content: sessionReplay.content, maxVisibleLines: sessionReplay.visibleLines)
            if(self.replay){
                DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                    self.startAutoScrolling(session: sessionReplay.session)
                }
            }else{
                DispatchQueue.main.asyncAfter(deadline: .now()){
                    self.repeatingCheck()
                }
            }
        }
    }
    
    func loadHardTableView(content: [Content], maxVisibleLines: Int) {
        
        let maxVisibleLines = maxVisibleLines
        
        let normalLineLabelHeight: CGFloat = hardTableView.frame.size.height / CGFloat(maxVisibleLines)
        let titleLabelHeight: CGFloat = hardTableView.frame.size.height
        
//        let isIpad = UIDevice.current.model.lowercased().contains("ipad")
        
        let cells: [HardTableView.Cell] = content.enumerated().map { index, content in
            
            let containerView = UIView()
            containerView.translatesAutoresizingMaskIntoConstraints = false

            let label = UILabel(frame: CGRect.zero)
            label.text = content.text
            label.translatesAutoresizingMaskIntoConstraints = false
            
            let cellHeight: CGFloat
            
            switch index {
            case 0:
                label.numberOfLines = 0
                label.font = self.titleFont
                label.textAlignment = .center
                cellHeight = titleLabelHeight
            default:
                label.font = self.font
                label.textAlignment = .justified
                cellHeight = normalLineLabelHeight
            }
            
            containerView.addSubview(label)
            
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: containerView.readableContentGuide.leadingAnchor),
                label.trailingAnchor.constraint(equalTo: containerView.readableContentGuide.trailingAnchor),
                label.topAnchor.constraint(equalTo: containerView.topAnchor),
                label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
//            if isIpad {
//                NSLayoutConstraint.activate([
//                    label.leadingAnchor.constraint(equalTo: containerView.readableContentGuide.leadingAnchor),
//                    label.trailingAnchor.constraint(equalTo: containerView.readableContentGuide.trailingAnchor),
//                ])
//            } else {
//
//            }
            
            return HardTableView.Cell(view: label, height: cellHeight)
            
        }
        
        let submitButton = UIButton(type: .system)
        submitButton.setTitle("Submit Reading", for: .normal)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(submitButton)
        
        let buttonSpacing: CGFloat = 8
        
        NSLayoutConstraint.activate([
            submitButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            submitButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            submitButton.topAnchor.constraint(lessThanOrEqualTo: containerView.topAnchor, constant: buttonSpacing),
            submitButton.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: buttonSpacing)
        ])
        
        let buttonCell = HardTableView.Cell(view: containerView, height: 44 + 2 * buttonSpacing)
        

        hardTableView.cells = cells + [buttonCell]
        hardTableView.backgroundColor = UIColor.purple
        
        hardTableView.layoutIfNeeded()
    }
    
    func startAutoScrolling(session: Session) {
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
    
    func repeatingCheck() {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.timer = Timer.init(timeInterval: self.timePerCheck, repeats: true, block: { _ in
                print(self.hardTableView.visibleIndices())
            })
            RunLoop.main.add(self.timer!, forMode: RunLoop.Mode.common)
            self.spinner?.stopAnimating()
        }
    }
    
    @objc func submitData() {
        _ = navigationController?.popViewController(animated: true)
    }
    

    
//    @objc func willResignActive(_ notification: Notification) {
//        _ = navigationController?.popViewController(animated: true)
//    }
}

extension ArticleViewController {
    
    
//    func convert(paragraphs: [String], font: UIFont) -> [Content] {
//        var cells = [Content].init()
//        var p = 0
//        var word_count = 0
//        var char_count = 0
//        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font]
//        cells.append(Content.init(text: paragraphs[0], paragraph: p, firstWordIndex: word_count, firstCharacterIndex: char_count, spacer: false))
//        p+=1
//        for section in paragraphs.dropFirst(){
//            var words = section.split(separator: " ").map({substring in
//                return String.init(substring)
//            })
//
//            while(!words.isEmpty){
//                var cell = [String]()
//                var temp = [words[0]]
//                while(!words.isEmpty && cellFit(string: temp.joined(separator: " "), attributes: attributes)){
//                    cell.append(words.removeFirst())
//                    if let w = words.first{
//                        temp = cell
//                        temp.append(w)
//                    }
//                }
//                word_count += cell.count
//                let current_text = cell.joined(separator: " ")
//                char_count += current_text.count
//                cells.append(Content.init(text: current_text, paragraph: p, firstWordIndex: word_count, firstCharacterIndex: char_count, spacer: false))
//
//            }
//            p += 1
//            cells.append(Content.init(text: "", paragraph: p, firstWordIndex: word_count, firstCharacterIndex: char_count, spacer: true))
//        }
//        return cells
//    }
    
    func viewableAreaHeight(showOnBottom: Bool) -> CGFloat {
        var viewableHeight = UIScreen.main.bounds.height - self.view.safeAreaInsets.top
        if !showOnBottom { viewableHeight = viewableHeight - self.view.safeAreaInsets.bottom }
        return viewableHeight
    }
}
