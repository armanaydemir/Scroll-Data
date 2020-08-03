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
    
    private func nearestCell(forIndex index: Int) -> Cell? {
        let nearestCell: Cell?
        
        if cells.indices.contains(index) {
            nearestCell = cells[index]
        } else if index < cells.indices.startIndex {
            nearestCell = cells.first
        } else {
            nearestCell = cells.last
        }
        
        return nearestCell
    }

    public func scrollToRow(index: Int, position: UITableView.ScrollPosition, animated: Bool) {
        guard let cell = nearestCell(forIndex: index) else { return }
        
        scrollToCell(cell: cell, position: position, animated: animated)
    }
    
    public func scrollToCell(cell: Cell, position: UITableView.ScrollPosition, animated: Bool) {
        guard let offset = contentOffset(forCell: cell, position: position) else { return }
        
        setContentOffset(offset, animated: animated)
    }
    
    public func contentOffset(forFractionalIndex fractionalIndex: CGFloat, position: UITableView.ScrollPosition) -> CGPoint? {
        let index = Int(floor(fractionalIndex))
        
        guard let cell = nearestCell(forIndex: index),
            let point = contentOffset(forCell: cell, position: position)
            else { return nil }

        let remainder = fractionalIndex.truncatingRemainder(dividingBy: 1)
        
        return CGPoint(x: 0, y: point.y + remainder * cell.height)
    }
    
    public func contentOffset(forIndex index: Int, position: UITableView.ScrollPosition) -> CGPoint? {
        guard let cell = nearestCell(forIndex: index) else { return nil }
        return contentOffset(forCell: cell, position: position)
    }
    
    public func contentOffset(forCell cell: Cell, position: UITableView.ScrollPosition) -> CGPoint? {
        guard let destinationOffset = cumulativeHeight[cell] else { return nil }
        
        let visibleHeight = frame.size.height
        
        let finalOffset: CGFloat
        
        switch position {
        case .top:
            finalOffset = destinationOffset
        case .bottom:
            finalOffset = max(destinationOffset - visibleHeight + cell.height, 0)
        case .middle:
            finalOffset = max(destinationOffset - (visibleHeight/2) + cell.height/2, 0)
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
        
        return CGPoint(x: 0, y: finalOffset)
    }
    
    public func visibleIndices() -> Range<CGFloat> {
        let minimumY = contentOffset.y
        let maximumY = minimumY + frame.size.height
        
        guard let firstVisibleCellObject = cumulativeHeight.filter({ $0.value + $0.key.height >= minimumY }).min(by: { $0.value < $1.value }),
            let lastVisibleCellObject = cumulativeHeight.filter({ $0.value < maximumY }).max(by: { $0.value < $1.value }),
            let firstVisibleIndex = cells.firstIndex(of: firstVisibleCellObject.key),
            let lastVisibleIndex = cells.firstIndex(of: lastVisibleCellObject.key)
            else { return 0..<0 }
        
        let firstVisibleCell = firstVisibleCellObject.key
        let lastVisibleCell = lastVisibleCellObject.key
        
        let firstCellTop = firstVisibleCellObject.value
        let lastCellTop = lastVisibleCellObject.value
        
        let firstIndexVisiblePortion = (minimumY - firstCellTop) / firstVisibleCell.height
        let lastIndexVisiblePortion = (maximumY - lastCellTop) / lastVisibleCell.height
        
        let top: CGFloat
        if firstIndexVisiblePortion < 0 {
            //scroll position is above top of first cell
            top = CGFloat(firstVisibleIndex)
        } else {
            top = CGFloat(firstVisibleIndex) + firstIndexVisiblePortion
        }
        
        let bottom: CGFloat
        if lastIndexVisiblePortion > 1 {
            //scroll position is below bottom of last cell
            bottom = CGFloat(lastVisibleIndex) + 1
        } else {
            bottom = CGFloat(lastVisibleIndex) + lastIndexVisiblePortion
        }
        
        return top..<bottom
    }
}
