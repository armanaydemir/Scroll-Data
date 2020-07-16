//
//  ArticleViewController.swift
//  Scroll Data
//
//  Created by Arman Aydemir on 3/31/18.
//  Copyright © 2018 Arman Aydemir. All rights reserved.
//

import UIKit

@objc class ArticleViewController: UIViewController {
    
    enum Mode {
        case read(viewModel: ReadArticleViewModel)
        case replay(viewModel: SessionReplayViewModel)
    }
    
    var mode: Mode?
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var hardTableView: HardTableView!
    
    private var lastVisibleIndices = 0..<0

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        
        spinner.hidesWhenStopped = true
        spinner.startAnimating()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        switch mode {
        case .read(let viewModel):
            setUpReadMode(viewModel: viewModel)
        case .replay(let viewModel):
            setUpReplayMode(viewModel: viewModel)
        case .none:
            print("Article mode not initialized correctly")
        }
    }
    
    func setUpReadMode(viewModel: ReadArticleViewModel) {
        viewModel.fetchText { result in
            switch result {
            case .success(let sessionReplay):
                DispatchQueue.main.async {
                    self.spinner.stopAnimating()
                    self.loadHardTableView(content: sessionReplay.content, maxVisibleLines: sessionReplay.visibleLines, includeSubmitButton: true)
                    self.hardTableView.delegate = self
                    self.lastVisibleIndices = self.hardTableView.visibleIndices()
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func setUpReplayMode(viewModel: SessionReplayViewModel) {
        viewModel.fetchSessionReplay { result in
            switch result {
            case .success(let sessionReplay):
                DispatchQueue.main.async {
                    self.spinner.stopAnimating()
                    self.loadHardTableView(content: sessionReplay.content, maxVisibleLines: sessionReplay.visibleLines, includeSubmitButton: false)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.startAutoScrolling(session: sessionReplay.session)
                    }                    }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func loadHardTableView(content: [Content], maxVisibleLines: Int, includeSubmitButton: Bool) {
        
        let maxVisibleLines = maxVisibleLines
        
        let tableHeight = hardTableView.frame.size.height
        let tableWidth = hardTableView.frame.size.width
        
        let normalLineLabelHeight: CGFloat = tableHeight  / CGFloat(maxVisibleLines)
        let titleLabelHeight: CGFloat = tableHeight
        
        let minimumMargin: CGFloat = 8
        let textWidth = min(tableHeight / 2, tableWidth - 2 * minimumMargin)
        let font = fittedFont(baseFont: defaultFont, cellHeight: normalLineLabelHeight, maxWidth: textWidth, content: content)
        
        let cells: [HardTableView.Cell] = content.enumerated().map { index, content in
            
            let containerView = UIView()
            containerView.translatesAutoresizingMaskIntoConstraints = false

            let label = UILabel(frame: CGRect.zero)
            label.text = content.text
            label.translatesAutoresizingMaskIntoConstraints = false
            
            let cellHeight: CGFloat
            
            let isTitle = index == 0
            
            if isTitle {
                label.numberOfLines = 0
                label.font = defaultFont.withTextStyle(.title1)!
                label.textAlignment = .center
                cellHeight = titleLabelHeight
            } else {
                label.font = font
                label.textAlignment = .justified
                cellHeight = normalLineLabelHeight
            }
            
            containerView.addSubview(label)
            
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: (tableWidth - textWidth) / 2),
                label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                label.topAnchor.constraint(equalTo: containerView.topAnchor),
                label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
            
            return HardTableView.Cell(view: containerView, height: cellHeight)
        }
        
        let finalCells: [HardTableView.Cell]
        
        if includeSubmitButton {
            finalCells = cells + [ createSubmitButtonCell() ]
        } else {
            finalCells = cells
        }

        hardTableView.cells = finalCells
        hardTableView.backgroundColor = UIColor.purple
    }
    
    func createSubmitButtonCell() -> HardTableView.Cell {
        let submitButton = UIButton(type: .system)
         submitButton.setTitle("Submit Reading", for: .normal)
         submitButton.translatesAutoresizingMaskIntoConstraints = false
         
         let containerView = UIView()
         containerView.translatesAutoresizingMaskIntoConstraints = false
         containerView.addSubview(submitButton)
         
         let buttonSpacing: CGFloat = 8
         let buttonHeight: CGFloat = 44
         
         NSLayoutConstraint.activate([
             submitButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
             submitButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
             submitButton.topAnchor.constraint(lessThanOrEqualTo: containerView.topAnchor, constant: buttonSpacing),
             submitButton.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: buttonSpacing),
             submitButton.heightAnchor.constraint(equalToConstant: buttonHeight)
         ])
         
         return HardTableView.Cell(view: containerView, height: buttonHeight + 2 * buttonSpacing)
    }
    
    func startAutoScrolling(session: Session) {
        let totalDuration = session.endTime - session.startTime
        
        let keyFrames: (() -> Void) = {
            session.relativePageStates.sorted { $0.relativeStartTime < $1.relativeStartTime }.forEach { pageState in
                
                print("\(pageState.firstLine), \(pageState.relativeStartTime * totalDuration), \(pageState.relativeDuration * totalDuration), \(pageState.contentOffset)")

                UIView.addKeyframe(withRelativeStartTime: pageState.relativeStartTime, relativeDuration: pageState.relativeDuration) {
                    self.hardTableView.scrollToRow(index: pageState.firstLine, position: .top, animated: false)
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
    
    @objc func submitData() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    
    func fittedFont(baseFont: UIFont, cellHeight: CGFloat, maxWidth: CGFloat, content: [Content]) -> UIFont {
        
        var fontSize = cellHeight - 3 //avoid cut off
        var attributes = [ NSAttributedString.Key.font : baseFont.withSize(fontSize) ]

        //get content with largest width, can use arbitrary font
        let longestLine = content.dropFirst().sorted { first, second in
            let firstWidth = (first.text as NSString).size(withAttributes: attributes).width
            let secondWidth = (second.text as NSString).size(withAttributes: attributes).width
            
            return firstWidth > secondWidth
        }.first
        
        guard let longestLineText = longestLine?.text as NSString? else { return baseFont.withSize(fontSize) }
        
        while (longestLineText.size(withAttributes: attributes).width >= maxWidth) {
            fontSize = fontSize - 1
            attributes = [ NSAttributedString.Key.font : baseFont.withSize(fontSize) ]
        }
        
        return baseFont.withSize(fontSize)
    }
}


extension ArticleViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        switch mode {
        case .read(let vm):
            let currentVisibleIndices = hardTableView.visibleIndices()
            if lastVisibleIndices != currentVisibleIndices {
                print("\(hardTableView.visibleIndices())")
                lastVisibleIndices = currentVisibleIndices
            }
            
            vm.submitData(content_offset: scrollView.contentOffset.y, first_index: currentVisibleIndices.startIndex, last_index: currentVisibleIndices.endIndex - 1)
        default: break
        }

    }
}
