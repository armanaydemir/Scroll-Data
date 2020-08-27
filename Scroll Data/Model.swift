//
//  Model.swift
//  Scroll Data
//
//  Created by Deniz Aydemir on 7/9/20.
//  Copyright © 2020 Arman Aydemir. All rights reserved.
//

import Foundation
import CoreGraphics


private let defaultMaxLines = 28

struct SessionBlurb: JSONParseable, UID {
    
    enum Key: String {
        case UDID
        case _id
        case article_id
        case completed
        case endTime
        case startTime
        case type
        case version
        case article_data
    }
    
    let id: String
    let article: ArticleBlurb

    let udid: String?
    let articleID: String?
    let startTime: Double?
    let endTime: Double?
    let deviceType: String?
    let readerVersion: String?
    
    init(data: Any?) throws {
        guard let data = data as? [String : Any],
            let id = data[Key._id.rawValue] as? String
            else { throw ModelError.errorParsingJSON }
        
        self.id = id
        self.article = try ArticleBlurb(data: data[Key.article_data.rawValue])
        
        self.udid = data[Key.UDID.rawValue] as? String
        self.articleID = data[Key.article_id.rawValue] as? String
        self.startTime = (data[Key.startTime.rawValue] as? Int)?.convertedTimeToRealTime()
        self.endTime = (data[Key.endTime.rawValue] as? Int)?.convertedTimeToRealTime()
        self.deviceType = data[Key.type.rawValue] as? String
        self.readerVersion = data[Key.version.rawValue] as? String
    }
}

public struct AbsolutePageState: JSONParseable, Equatable, Hashable {
    
    enum Key: String {
        case appeared
        case time
        case content_offset
        case first_cell
        case last_cell
        case position
    }
    
    public let position: Int?
    
    public let startTime: TimeInterval
    public let duration: TimeInterval
    
    public let contentOffset: CGFloat
    
    public let firstLine: CGFloat
    public let lastLine: CGFloat
    
    public init(data: Any?) throws {
        guard let data = data as? [String : Any],
            let convertedAppearTime = data[Key.appeared.rawValue] as? Int,
            let firstCell = data[Key.first_cell.rawValue] as? CGFloat,
            let lastCell = data[Key.last_cell.rawValue] as? CGFloat,
            let convertedDuration = data[Key.time.rawValue] as? Int,
            let contentOffset = data[Key.content_offset.rawValue] as? CGFloat
            else { throw ModelError.errorParsingJSON }
        
        let appearTime = convertedAppearTime.convertedTimeToRealTime()
        let momentDuration = convertedDuration.convertedTimeToRealTime()

        self.startTime = appearTime
        self.duration = momentDuration
        
        self.contentOffset = contentOffset
        self.firstLine = firstCell
        self.lastLine = lastCell
        
        self.position = data[Key.position.rawValue] as? Int
    }
    
    public init(startTime: TimeInterval, duration: TimeInterval, contentOffset: CGFloat, firstLine: CGFloat, lastLine: CGFloat, position: Int?) {
        self.startTime = startTime
        self.duration = duration
        
        self.contentOffset = contentOffset
        self.firstLine = firstLine
        self.lastLine = lastLine
        self.position = position
    }
    
    func toDictionary() -> [String : Any] {
        return [ Key.appeared.rawValue : startTime.realTimeToConvertedTime(),
                 Key.time.rawValue : duration.realTimeToConvertedTime(),
                 Key.first_cell.rawValue : firstLine,
                 Key.last_cell.rawValue : lastLine,
                 Key.content_offset.rawValue : contentOffset,
                 Key.position.rawValue : self.position ?? "" ]
    }
    
    public static func < (lhs: AbsolutePageState, rhs: AbsolutePageState) -> Bool {
        return lhs.startTime < rhs.startTime
    }
}

struct Session: JSONParseable {
    
    enum Key: String {
        case session_data
        case article_data
        case max_lines
    }
    
    let states: [AbsolutePageState]
    let article: Article
    let maxLines: Int
    
    init(data: Any?) throws {
        guard let data = data as? [String : Any]
            else { throw ModelError.errorParsingJSON }
        
        self.article = try Article(data: data[Key.article_data.rawValue])
        self.states = try [AbsolutePageState].init(data: data[Key.session_data.rawValue])

        let maxLines: Double
        if let v = data[Key.max_lines.rawValue] as? Double {
            maxLines = v
        } else {
            maxLines = Double(defaultMaxLines)
            print("No visible lines count sent from server, using default of \(maxLines)")
        }
        
        self.maxLines = Int(maxLines)
    }
}


struct ReadingSession: JSONParseable {
    
    enum Key: String {
        case article_data
        case max_lines
        case sessionID
        case questions
    }
    
    let visibleLines: Int
    let sessionID: String
    let article: Article
    let questions: [Question]?
    
    init(data: Any?) throws {
        guard let data = data as? [String : Any],
            let sessionID = data[Key.sessionID.rawValue] as? String
            else { throw ModelError.errorParsingJSON }
        
        self.visibleLines = data[Key.max_lines.rawValue] as? Int ?? defaultMaxLines
        self.sessionID = sessionID
        self.article = try Article(data: data[Key.article_data.rawValue])
        self.questions = try? [Question].init(data: data[Key.questions.rawValue])
    }
}

struct Question: JSONParseable, UID {
    
    enum Key: String {
        case id
        case text
        case options
    }
    
    let id: String
    let text: String
    let options: [Option]
    
    init(data: Any?) throws {
        guard let data = data as? [String : Any],
            let id = data[Key.id.rawValue] as? String,
            let text = data[Key.text.rawValue] as? String
            else { throw ModelError.errorParsingJSON }
        
        self.id = id
        self.text = text
        self.options = try [Option].init(data: data[Key.options.rawValue])
    }
    
    struct Option: JSONParseable, UID {
        
        enum Key: String {
            case id
            case text
        }
        
        let id: String
        let text: String
        
        init(data: Any?) throws {
            guard let data = data as? [String : Any],
                let id = data[Key.id.rawValue] as? String,
                let text = data[Key.text.rawValue] as? String
                else { throw ModelError.errorParsingJSON }
            
            self.id = id
            self.text = text
        }
    }
}


struct Article: JSONParseable {
    
    enum Key: String {
        case content
    }
    
    let content: [String]
    let info: ArticleBlurb
    
    init(data: Any?) throws {
        guard let data = data as? [String : Any],
            let content = data[Key.content.rawValue] as? [String]
            else { throw ModelError.errorParsingJSON }
               
        self.content = content
        self.info = try ArticleBlurb(data: data)
    }
}


struct ArticleBlurb: JSONParseable {
    
    enum Key: String {
        case title
        case abstract
        case url
        case short_url
        case created_date
        case date_written
        case published_date
        case byline
        case line_count
    }
    
    let title: String
    let abstract: String?
    let url: String
    let shortURL: String?
    let createdDate: String?
    let dateWritten: String?
    let publishedDate: String?
    let byline: String?
    let lineCount: Int?
    
    init(data: Any?) throws {
        guard let data = data as? [String : Any],
            let title = data[Key.title.rawValue] as? String,
            let url = data[Key.url.rawValue] as? String
            else { throw ModelError.errorParsingJSON }
        
        self.title = title
        self.url = url
        
        self.abstract = data[Key.abstract.rawValue] as? String
        self.shortURL = data[Key.short_url.rawValue] as? String
        self.createdDate = data[Key.created_date.rawValue] as? String
        self.dateWritten = data[Key.date_written.rawValue] as? String
        self.publishedDate = data[Key.published_date.rawValue] as? String
        self.byline = data[Key.byline.rawValue] as? String
        self.lineCount = data[Key.line_count.rawValue] as? Int
    }
}


struct Settings: JSONParseable {
    
    private let defaultShowSessions = false
    
    enum Key: String {
        case showReplays
    }
    
    let showSessions: Bool
    
    init(data: Any?) {
        if let data = data as? [String : Any],
            let showSessions = data[Key.showReplays.rawValue] as? Bool {
            self.showSessions = showSessions
        } else {
            self.showSessions = defaultShowSessions
        }
    }
    
    init() {
        self.showSessions = defaultShowSessions
    }
}

private let timeOffset = 100000000.0

extension Int {
    func convertedTimeToRealTime() -> TimeInterval {
        return Double(self) / timeOffset
    }
}

public enum ModelError: Error {
    case errorParsingJSON
}


extension TimeInterval {
    
    func realTimeToConvertedTime() -> Int {
        return Int(self*timeOffset)
    }
    
    func asDate() -> Date {
        return Date(timeIntervalSinceReferenceDate: self)
    }
    
    func asDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: self.asDate())
    }
}


protocol UID: Equatable {
    var id: String { get }
}

func ==<T: UID>(lhs: T, rhs: T) -> Bool {
    return lhs.id == rhs.id
}
