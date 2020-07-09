//
//  Model.swift
//  Scroll Data
//
//  Created by Deniz Aydemir on 7/9/20.
//  Copyright © 2020 Arman Aydemir. All rights reserved.
//

import Foundation
import CoreGraphics

private let timeOffset = 100000000.0
private let sessionDataKey = "session_data"
private let appearedTimeKey = "appeared"
private let startTimeKey = "startTime"
private let lastCellKey = "last_cell"
private let firstCellKey = "first_cell"
private let timeKey = "time"
private let contentOffsetKey = "content_offset"

public struct Session {
    public let pageStates: [PageState]
    
    public let totalDuration: TimeInterval
    public let linesPerPage: Int = 20 //TODO: should come from server
    
    public init(data: Any) throws {
        guard let data = data as? [String : Any],
            let sessionData = data[sessionDataKey] as? [[String : Any]],
            let unconvertedStartTime = sessionData.first?[startTimeKey] as? Int,
            let unconvertedEndTime = sessionData.last?[appearedTimeKey] as? Int
            else { throw ModelError.errorParsingJSON }
        
        let startTime = Double(unconvertedStartTime)/timeOffset
        let endTime = Double(unconvertedEndTime)/timeOffset
        
        let totalDuration = endTime - startTime
                
        let states: [PageState] = sessionData.compactMap { pageStateData in
            guard let unconvertedAppearTime = pageStateData[appearedTimeKey] as? Int,
                let firstCell = pageStateData[firstCellKey] as? Int,
                let lastCell = pageStateData[lastCellKey] as? Int,
                let unconvertedDuration = pageStateData[timeKey] as? Int,
                let contentOffset = pageStateData[contentOffsetKey] as? CGFloat
                else { return nil }
            
            let appearTime = Double(unconvertedAppearTime) / timeOffset
            let relativeStartTime = (appearTime - startTime) / totalDuration
            
            let momentDuration = Double(unconvertedDuration) / timeOffset
            let relativeDuration = (momentDuration - appearTime) / totalDuration
            
            return PageState(relativeStartTime: relativeStartTime, relativeDuration: relativeDuration, contentOffset: contentOffset, firstLine: firstCell, lastLine: lastCell)
        }
        
        self.totalDuration = totalDuration
        self.pageStates = states
    }
}

public struct PageState {
    public let relativeStartTime: Double
    public let relativeDuration: Double
    
    public let contentOffset: CGFloat
    
    public let firstLine: Int
    public let lastLine: Int
}

let textKey = "text"
let paragraphKey = "paragraph"
let firstWordIndexKey = "first_word_index"
let firstCharacterIndexKey = "first_character_index"
let spacerKey = "spacer"

struct Content: Codable {
    let text: String
    let paragraph: Int
    let firstWordIndex: Int
    let firstCharacterIndex: Int
    let spacer: Bool
    
    
    func toDictionary() -> [String : Any] {
        return [
            textKey : text,
            paragraphKey : paragraph,
            firstWordIndexKey : firstWordIndex,
            firstCharacterIndexKey : firstCharacterIndex,
            spacerKey : spacer,
        ]
    }
    
    init(data: Any?) throws {
        guard let data = data as? [String : Any],
            let text = data[textKey] as? String,
            let paragraph = data[paragraphKey] as? Int,
            let firstWordIndex = data[firstWordIndexKey] as? Int,
            let firstCharacterIndex = data[firstCharacterIndexKey] as? Int,
            let spacer = data[spacerKey] as? Bool
            else { throw ModelError.errorParsingJSON }
        
        self.init(text: text,
                  paragraph: paragraph,
                  firstWordIndex: firstWordIndex,
                  firstCharacterIndex: firstCharacterIndex,
                  spacer: spacer)
    }
    
    init(text: String, paragraph: Int, firstWordIndex: Int, firstCharacterIndex: Int, spacer: Bool) {
        self.text = text
        self.paragraph = paragraph
        self.firstWordIndex = firstWordIndex
        self.firstCharacterIndex = firstCharacterIndex
        self.spacer = spacer
    }
}


public enum ModelError: Error {
    case errorParsingJSON
}
