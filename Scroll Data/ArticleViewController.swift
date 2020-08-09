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
    
    @IBOutlet weak var loadingBarView: UIView!
    @IBOutlet weak var loadingBarWidth: NSLayoutConstraint!
    
    private var lastVisibleIndices: Range<CGFloat> = 0..<0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        spinner.hidesWhenStopped = true
        spinner.startAnimating()
        hardTableView.isHidden = true
        loadingBarView.isHidden = true
        
        self.hardTableView.delegate = self
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
    
    override func viewWillDisappear(_ animated: Bool) {
        switch mode {
        case .read(let vm):
            vm.leavingArticle()
        default:
            break
        }
    }
    
    @objc func logEvent(notification: Notification) {
        if let mode = self.mode, case Mode.read(let vm) = mode {
            vm.logEvent(notification: notification)
        }
    }
    
    func setUpReadMode(viewModel: ReadArticleViewModel) {
        NotificationCenter.default.addObserver(self, selector: #selector(logEvent(notification:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(logEvent(notification:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(logEvent(notification:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(logEvent(notification:)), name: UIApplication.willEnterForegroundNotification, object: nil)

        viewModel.fetchText { result in
            switch result {
            case .success(let articleResponse):
                DispatchQueue.main.async {
                    self.loadHardTableView(content: articleResponse.article.content, maxVisibleLines: articleResponse.visibleLines, includeSubmitButton: true)
                    
                    self.spinner.stopAnimating()
                    self.hardTableView.isHidden = false
                    
                    self.scrollViewDidScroll(self.hardTableView)
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func setUpReplayMode(viewModel: SessionReplayViewModel) {
        viewModel.fetchSessionReplay { result in
            switch result {
            case .success(let playableSession):
                DispatchQueue.main.async {
                    self.loadHardTableView(content: playableSession.article.content, maxVisibleLines: playableSession.maxLines, includeSubmitButton: false)
                    
                    let timeLabel = UILabel()
                    timeLabel.font = UIFont.systemFont(ofSize: 12)
                    let totalDuration = playableSession.endTime - playableSession.startTime
                    timeLabel.text = "\(Int(totalDuration.rounded(FloatingPointRoundingRule.toNearestOrAwayFromZero)))s"
                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: timeLabel)
                    
                    self.navigationItem.title = playableSession.startTime.asDateString()
                    
                    self.spinner.stopAnimating()
                    self.hardTableView.isHidden = false

                    DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                        //not animating loading bar for now, not working yet
                        //animateLoadingBar(totalDuration: totalDuration)
                        
                        self.startAutoScrolling(session: playableSession)
                        print(playableSession.article.content.count)
                    }    
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func loadHardTableView(content: [String], maxVisibleLines: Int, includeSubmitButton: Bool) {

        let contentCells = createContentCells(content: content, maxVisibleLines: maxVisibleLines)
        let buttonCell = [ createSubmitButtonCell(totalHeight: hardTableView.bounds.height, emptyPlaceholder: !includeSubmitButton) ]

        hardTableView.cells = contentCells + buttonCell
    }
    
    func createContentCells(content: [String], maxVisibleLines: Int) -> [HardTableView.Cell] {
        let tableHeight = hardTableView.frame.size.height
        let tableWidth = hardTableView.frame.size.width

        let normalLineLabelHeight: CGFloat = tableHeight  / CGFloat(maxVisibleLines)
        let spacingLineLabelHeight: CGFloat = normalLineLabelHeight
        
        let readableTextAspectRatio: CGFloat = 2

        let minimumMargin: CGFloat = 8
        let textWidth = min(tableHeight / readableTextAspectRatio, tableWidth - 2 * minimumMargin)
        let font = fittedFont(baseFont: baseFont, cellHeight: normalLineLabelHeight, maxWidth: textWidth, content: content)

        let cells: [HardTableView.Cell] = content.enumerated().map { index, content in
            let containerView = UIView()
            containerView.translatesAutoresizingMaskIntoConstraints = false

            let label = UILabel(frame: CGRect.zero)
            label.text = content
            label.translatesAutoresizingMaskIntoConstraints = false

            let cellHeight: CGFloat
            let isTitle = index == 0
            let isSpacer = content == ""

            if isTitle {
               return createTitleCell(totalHeight: tableHeight, title: content)
            } else if isSpacer {
               cellHeight = spacingLineLabelHeight
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

        return cells
    }
    
    func createTitleCell(totalHeight: CGFloat, title: String) -> HardTableView.Cell {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel(frame: CGRect.zero)
        label.text = title
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = baseFont.withTextStyle(.title1)!
        label.textAlignment = .center
        label.numberOfLines = 0

        
        let caret = UIImageView()
        caret.tintColor = UIColor.darkText
        caret.image = UIImage(systemName: "chevron.down", withConfiguration: UIImage.SymbolConfiguration(scale: .large))
        caret.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(label)
        containerView.addSubview(caret)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: containerView.leadingAnchor, multiplier: 2),
            caret.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            caret.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -32)
        ])
        
        return HardTableView.Cell(view: containerView, height: totalHeight)
    }
    
    func createSubmitButtonCell(totalHeight: CGFloat, emptyPlaceholder: Bool = false) -> HardTableView.Cell {
        
        let buttonTopSpacing: CGFloat = 44
        let buttonHeight: CGFloat = 64
        let buttonBottomSpacing: CGFloat = totalHeight - buttonTopSpacing - buttonHeight
        
        let submitButton = UIButton(type: .system)
        submitButton.setTitle("Submit Reading", for: .normal)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.addTarget(self, action: #selector(self.submitData(_:)), for: .touchUpInside)
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(submitButton)

        NSLayoutConstraint.activate([
           submitButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
           submitButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: buttonTopSpacing),
           submitButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -1*buttonBottomSpacing),
           submitButton.heightAnchor.constraint(equalToConstant: buttonHeight)
        ])
        
        submitButton.isEnabled = !emptyPlaceholder

        return HardTableView.Cell(view: containerView, height: totalHeight)
    }
    
    @objc func submitData(_ sender: UIButton) {
        
        switch self.mode {
        case .read(let vm):
            vm.closeArticle(complete: true)
        default:
            break
        }
        
        _ = navigationController?.popViewController(animated: true)
    }
    
    private func animateLoadingBar(totalDuration: TimeInterval) {
        loadingBarView.isHidden = true
        loadingBarWidth.constant = view.bounds.width
        UIView.animate(withDuration: totalDuration) {
            self.loadingBarView.layoutIfNeeded()
        }
    }
    
    func startAutoScrolling(session: PlayableSession) {
        let totalDuration = session.endTime - session.startTime
        
        let tableWidth = hardTableView.bounds.width
        let tableHeight = hardTableView.bounds.height

        let stateTuples: [(state: RelativePageState, bounds: CGRect)] = session.states.compactMap { pageState in
            
//            print("\(pageState.firstLine), \(pageState.lastLine), \(pageState.relativeStartTime * totalDuration), \(pageState.relativeDuration * totalDuration), \(pageState.contentOffset)")
            
            guard let contentOffset = self.hardTableView.contentOffset(forFractionalIndex: pageState.firstLine, position: UITableView.ScrollPosition.top)
                else { return nil }

            let rect = CGRect(x: contentOffset.x, y: contentOffset.y, width: tableWidth, height: tableHeight)
            return (state: pageState, bounds: rect)
        }
        
        let animation = CAKeyframeAnimation(keyPath: "bounds")
        animation.values = stateTuples.map { $0.bounds }
        animation.keyTimes = stateTuples.map { NSNumber(value: $0.state.relativeStartTime) }
        animation.calculationMode = .linear
        animation.duration = totalDuration
        animation.isCumulative = true
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false

        self.hardTableView.layer.add(animation, forKey: nil)
    }
    
    
    func fittedFont(baseFont: UIFont, cellHeight: CGFloat, maxWidth: CGFloat, content: [String]) -> UIFont {
        
        var fontSize = cellHeight - 3 //avoid cut off
        var attributes = [ NSAttributedString.Key.font : baseFont.withSize(fontSize) ]

        //get content with largest width, can use arbitrary font
        let longestLine = content.dropFirst().sorted { first, second in
            let firstWidth = (first as NSString).size(withAttributes: attributes).width
            let secondWidth = (second as NSString).size(withAttributes: attributes).width
            
            return firstWidth > secondWidth
        }.first
        
        guard let longestLineText = longestLine as NSString? else { return baseFont.withSize(fontSize) }
        
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
            
            vm.submitData(content_offset: scrollView.contentOffset.y, first_index: currentVisibleIndices.lowerBound, last_index: currentVisibleIndices.upperBound)
        default: break
        }
    }
}
