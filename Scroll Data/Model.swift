//
//  Model.swift
//  Scroll Data
//
//  Created by Deniz Aydemir on 7/9/20.
//  Copyright © 2020 Arman Aydemir. All rights reserved.
//

import Foundation
import CoreGraphics


//Server session model

private let timeOffset = 100000000.0
private let sessionDataKey = "session_data"
private let appearedTimeKey = "appeared"
private let startTimeKey = "startTime"
private let lastCellKey = "last_cell"
private let firstCellKey = "first_cell"
private let timeKey = "time"
private let contentOffsetKey = "content_offset"
private let linesPerPageKey = "visible_lines"


public struct Session {
    public let absolutePageStates: [AbsolutePageState]
    public let linesPerPage: Int

    public let startTime: TimeInterval
    public let endTime: TimeInterval
    public let relativePageStates: [RelativePageState]
    
    public init(data: Any) throws {
        guard let data = data as? [String : Any],
            let sessionData = data[sessionDataKey] as? [[String : Any]],
            let unconvertedStartTime = sessionData.first?[startTimeKey] as? Int,
            let unconvertedEndTime = sessionData.last?[appearedTimeKey] as? Int
            else { throw ModelError.errorParsingJSON }
        
        let linesPerPage = sessionData.last?[linesPerPageKey] as? Int ?? 20 //TODO: remove temporary hardcoding
        
        let startTime = Double(unconvertedStartTime)/timeOffset
        let endTime = Double(unconvertedEndTime)/timeOffset
        
        let states = sessionData.compactMap { try? AbsolutePageState(data: $0) }
        
        self.startTime = startTime
        self.endTime = endTime
        self.absolutePageStates = states
        self.relativePageStates = states.map { $0.convertToRelative(sessionStartTime: startTime, totalSessionDuration: endTime - startTime)}
        self.linesPerPage = linesPerPage
    }
    
    public init(startTime: TimeInterval, endTime: TimeInterval, absolutePageStates: [AbsolutePageState], linesPerPage: Int) {
        self.absolutePageStates = absolutePageStates
        self.startTime = startTime
        self.endTime = endTime
        self.linesPerPage = linesPerPage
        
        self.relativePageStates = absolutePageStates.map { $0.convertToRelative(sessionStartTime: startTime, totalSessionDuration: endTime - startTime) }
    }
    
    public func toDictionary() -> [String : Any] {
        return [ sessionDataKey : absolutePageStates.map { $0.toDictionary() },
                 linesPerPageKey : linesPerPage ]
    }
}

public struct AbsolutePageState {
    public let startTime: TimeInterval
    public let duration: TimeInterval
    
    public let contentOffset: CGFloat
    
    public let firstLine: Int
    public let lastLine: Int
    
    public init(data: Any?) throws {
        guard let data = data as? [String : Any],
            let unconvertedAppearTime = data[appearedTimeKey] as? Int,
            let firstCell = data[firstCellKey] as? Int,
            let lastCell = data[lastCellKey] as? Int,
            let unconvertedDuration = data[timeKey] as? Int,
            let contentOffset = data[contentOffsetKey] as? CGFloat
            else { throw ModelError.errorParsingJSON }
        
        let appearTime = Double(unconvertedAppearTime) / timeOffset
        let momentDuration = Double(unconvertedDuration) / timeOffset


        self.startTime = appearTime
        self.duration = momentDuration
        
        self.contentOffset = contentOffset
        self.firstLine = firstCell
        self.lastLine = lastCell
    }
    
    public init(startTime: TimeInterval, duration: TimeInterval, contentOffset: CGFloat, firstLine: Int, lastLine: Int) {
        self.startTime = startTime
        self.duration = duration
        
        self.contentOffset = contentOffset
        self.firstLine = firstLine
        self.lastLine = lastLine
    }
    
    public func toDictionary() -> [String : Any] {
        return [ appearedTimeKey : Int(startTime * timeOffset),
                 timeKey : Int(duration * timeOffset),
                 firstCellKey : firstLine,
                 lastCellKey : lastLine,
                 contentOffsetKey : contentOffset ]
    }
    
    fileprivate func convertToRelative(sessionStartTime: TimeInterval, totalSessionDuration: TimeInterval) -> RelativePageState {
        return RelativePageState(absolutePageState: self,
                                 sessionStartTime: sessionStartTime,
                                 totalSessionDuration: totalSessionDuration)
    }
}


//Specific page state version for use in session playback

public struct RelativePageState {
    public let relativeStartTime: Double
    public let relativeDuration: Double
    
    public let contentOffset: CGFloat
    
    public let firstLine: Int
    public let lastLine: Int

    
    public init(absolutePageState: AbsolutePageState, sessionStartTime: TimeInterval, totalSessionDuration: TimeInterval) {
        self.contentOffset = absolutePageState.contentOffset
        self.firstLine = absolutePageState.firstLine
        self.lastLine = absolutePageState.lastLine
        
        let relativeStartTime = (absolutePageState.startTime - sessionStartTime) / totalSessionDuration
        let relativeDuration = (absolutePageState.duration - absolutePageState.startTime) / totalSessionDuration
        
        self.relativeStartTime = relativeStartTime
        self.relativeDuration = relativeDuration
    }
    
    
}



//Content

private let textKey = "text"
private let paragraphKey = "paragraph"
private let firstWordIndexKey = "first_word_index"
private let firstCharacterIndexKey = "first_character_index"
private let spacerKey = "spacer"

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
