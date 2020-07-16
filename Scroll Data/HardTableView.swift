//
//  HardTableView.swift
//  Scroll Data
//
//  Created by Deniz Aydemir on 7/8/20.
//  Copyright © 2020 Arman Aydemir. All rights reserved.
//

import UIKit

class HardTableView: UIScrollView {
    
    public struct Cell: Equatable, Hashable {
        public let view: UIView
        public let height: CGFloat
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.view == rhs.view
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(view)
            hasher.combine(height)
        }
    }

    public let contentView: UIView = UIView()
    
    public var cells: [Cell] = [] {
        didSet {
            updateCells(newCells: cells, oldCells: oldValue)
        }
    }
    
    private var cumulativeHeight: [Cell : CGFloat] = [:]
    private lazy var contentHeightConstraint: NSLayoutConstraint = contentView.heightAnchor.constraint(equalToConstant: 0)
    
    
    override func awakeFromNib() {
        setUpContentView()
        contentViewConstraints()
    }
    
    private func setUpContentView() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
    }
    
    private func contentViewConstraints() {
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor, constant: 0),
            contentView.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor, constant: 0),
            contentView.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor, constant: 0),
            contentView.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor, constant: 0),
            
            contentView.widthAnchor.constraint(equalTo: frameLayoutGuide.widthAnchor, multiplier: 1),
            contentHeightConstraint
        ])
        
        layoutIfNeeded()
    }
    
    private func updateCells(newCells: [Cell], oldCells: [Cell]) {
        oldCells.forEach { $0.view.removeFromSuperview() }
        
        contentHeightConstraint.constant = newCells.reduce(0) { result, current in
            self.cumulativeHeight[current] = result
            return result + current.height
        }
        
        let indices = newCells.indices
        newCells.enumerated().forEach { index, cell in
            
            let view = cell.view
            
            contentView.addSubview(view)
            
            //vertical constraints
            var verticalConstraints: [NSLayoutConstraint] = []
            
            switch index {
            case indices.startIndex:
                verticalConstraints.append(view.topAnchor.constraint(equalTo: contentView.topAnchor))
            case indices.endIndex - 1:
                verticalConstraints.append(view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor))
                fallthrough
            default:
                verticalConstraints.append(view.topAnchor.constraint(equalTo: newCells[index-1].view.bottomAnchor))
            }
            
            //height, and horizontal
            NSLayoutConstraint.activate([
                view.heightAnchor.constraint(equalToConstant: cell.height),
                view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
                view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0)
            ] + verticalConstraints)
        }
        
        layoutIfNeeded()
    }

    
    public func scrollToRow(index: Int, position: UITableView.ScrollPosition, animated: Bool) {
        guard cells.indices.contains(index) else { return }

        scrollToCell(cell: cells[index], position: position, animated: animated)
    }
    
    public func scrollToCell(cell: Cell, position: UITableView.ScrollPosition, animated: Bool) {
        guard let destinationOffset = cumulativeHeight[cell] else { return }
        
        let visibleHeight = frame.size.height
        
        let finalOffset: CGFloat
        
        switch position {
        case .top:
            finalOffset = destinationOffset
        case .bottom:
            finalOffset = max(destinationOffset - visibleHeight, 0)
        case .middle:
            finalOffset = max(destinationOffset - (visibleHeight/2), 0)
        default:
            let currentOffset = contentOffset.y
            
            if currentOffset > destinationOffset {
                finalOffset = destinationOffset
            } else if currentOffset + visibleHeight < destinationOffset {
                finalOffset = max(destinationOffset - visibleHeight, 0)
            } else {
                finalOffset = currentOffset
            }
        }
        
        setContentOffset(CGPoint(x: 0, y: finalOffset), animated: animated)
    }
    
    public func visibleIndices() -> Range<Int> {
        let minimumY = contentOffset.y
        let maximumY = minimumY + frame.size.height
        
        
        guard let firstVisibleCell = cumulativeHeight.filter({ $0.value >= minimumY }).min(by: { $0.value < $1.value })?.key ?? cells.first,
            let firstInvisibleCell = cumulativeHeight.filter({ $0.value >= maximumY }).min(by: { $0.value < $1.value })?.key ?? cells.last,
            let firstIndex = cells.firstIndex(of: firstVisibleCell),
            let firstInvisibleIndex = cells.firstIndex(of: firstInvisibleCell)
            else { return 0..<0 }
        
        return firstIndex..<firstInvisibleIndex
    }
}
