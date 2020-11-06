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
    
    private static let defaultShowSessions = false
    private static let defaultIntroHTML = backupIntroHTML
    
    enum Key: String {
        case showReplays
        case intro_html
    }
    
    let showSessions: Bool
    let introHTML: String
    
    init(data: Any?) {
        if let data = data as? [String : Any] {
            self.showSessions = (data[Key.showReplays.rawValue] as? Bool) ?? Settings.defaultShowSessions
            self.introHTML = (data[Key.intro_html.rawValue] as? String) ?? Settings.defaultIntroHTML
        } else {
            self.showSessions = Settings.defaultShowSessions
            self.introHTML = Settings.defaultIntroHTML
        }
    }
    
    init() {
        self.showSessions = Settings.defaultShowSessions
        self.introHTML = Settings.defaultIntroHTML
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

fileprivate let backupIntroHTML = """
<h2><strong><em><img src="https://www.colorado.edu/brand/sites/default/files/page/boulder-fl-master-2_0.png" alt="" width="429" height="87" /><br /></em></strong></h2>
<h2>&nbsp;</h2>
<h2><strong><em>Title of research study: </em></strong><span style="font-weight: 400;">Operationalizing Students&rsquo; Textbook Annotations</span></h2>
<h2><strong><em>Investigator: </em></strong><span style="font-weight: 400;">Arman Aydemir</span></h2>
<h2><strong><em>Why am I being invited to take part in a research study?</em></strong></h2>
<p><span style="font-weight: 400;">We invite you to take part in a research study because you are at least 18 years old, have normal vision or wear corrective lenses, are a fluent English speaker and have not previously participated in the experiment.</span></p>
<h2><strong><em>What should I know about a research study?</em></strong></h2>
<ul>
<li style="font-weight: 400;"><span style="font-weight: 400;">This research study will be explained to you.</span></li>
<li style="font-weight: 400;"><span style="font-weight: 400;">Whether or not you take part is up to you.</span></li>
<li style="font-weight: 400;"><span style="font-weight: 400;">You can choose not to take part.</span></li>
<li style="font-weight: 400;"><span style="font-weight: 400;">You can agree to take part and later change your mind.</span></li>
<li style="font-weight: 400;"><span style="font-weight: 400;">Your decision will not be held against you.</span></li>
<li style="font-weight: 400;"><span style="font-weight: 400;">You can ask all the questions you want before you decide.</span></li>
</ul>
<h2><strong><em>Who can I talk to?</em></strong></h2>
<p><span style="font-weight: 400;">If you have questions, concerns, or complaints, or think the research has hurt you, talk to the research team by emailing Arman Aydemir at arman.aydemir@colorado.edu.</span></p>
<p><span style="font-weight: 400;">This research has been reviewed and approved by an Institutional Review Board (&ldquo;IRB&rdquo;). You may talk to them at (303) 735-3702 or </span><strong>irbadmin@colorado.edu</strong><span style="font-weight: 400;"> if:</span></p>
<ul>
<li style="font-weight: 400;"><span style="font-weight: 400;">Your questions, concerns, or complaints are not being answered by the research team.</span></li>
<li style="font-weight: 400;"><span style="font-weight: 400;">You cannot reach the research team.</span></li>
<li style="font-weight: 400;"><span style="font-weight: 400;">You want to talk to someone besides the research team.</span></li>
<li style="font-weight: 400;"><span style="font-weight: 400;">You have questions about your rights as a research subject.</span></li>
<li style="font-weight: 400;"><span style="font-weight: 400;">You want to get information or provide input about this research.</span></li>
</ul>
<h2><strong><em>Why is this research being done?</em></strong></h2>
<p><span style="font-weight: 400;">The purpose of this research is to understand the relationship between the understanding of a presented text and the subject&rsquo;s annotations of and interactions with the text. </span><span style="font-weight: 400;">By conducting a series of such experiments, we hope to enhance online textbooks so as to facilitate students&rsquo; long-term understanding and retention of textbook content.</span></p>
<p>&nbsp;</p>
<h2><strong><em>How long will the research last?</em></strong></h2>
<p><span style="font-weight: 400;">We expect that this research study will last for 3 years.</span></p>
<h2><strong><em>How many people will be studied?</em></strong></h2>
<p><span style="font-weight: 400;">We expect about 40 people will be in this research study.</span></p>
<h2><strong><em>What happens if I say yes, I want to be in this research?</em></strong></h2>
<ul>
<li style="font-weight: 400;"><span style="font-weight: 400;">You will be using your own portable device to complete the study at a time of your choosing.</span></li>
<li style="font-weight: 400;"><span style="font-weight: 400;">This app will allow you to read articles from a news source or science magazine or biology textbook. The app will also allow you to quiz yourself on material you have previously read.&nbsp;</span></li>
<li style="font-weight: 400;"><span style="font-weight: 400;">When and how much you use this app, and when and whether you take quizzes will be up to you.</span></li>
<li style="font-weight: 400;"><span style="font-weight: 400;">We will record your screen interactions and annotations along with your apple ID. No other personal data will be requested.</span></li>
</ul>
<h2><strong><em>What happens if I do not want to be in this research?</em></strong></h2>
<p><span style="font-weight: 400;">You can leave the research at any time and it will not be held against you.</span></p>
<h2><strong><em>What happens if I say yes, but I change my mind later?</em></strong></h2>
<p><span style="font-weight: 400;">You can leave the research at any time and it will not be held against you. If you choose to leave during the experiment, any data collected will be permanently deleted.</span></p>
<h2><strong><em>What happens to the information collected for the research?</em></strong></h2>
<p><span style="font-weight: 400;">Efforts will be made to limit the use and disclosure of behavioral data collected during this research study to people who have a need to review this information. We cannot promise complete secrecy. Organizations that may inspect and copy your information include the IRB and other representatives of this organization. In addition, representatives of University of Colorado Boulder and the National Science Foundation may inspect and copy this information.</span></p>
<p><span style="font-weight: 400;">All data collected will be stored on a secure server indefinitely and will only be accessible by the research team.</span></p>
<h2><strong><em>Can I be removed from the research without my OK?</em></strong></h2>
<p><span style="font-weight: 400;">The person in charge of the research study or the sponsor can remove you from the research study without your approval. Possible reasons for removal include the inability to follow study procedures.</span></p>
<h2><strong><em>What else do I need to know?</em></strong></h2>
<p><span style="font-weight: 400;">If you agree to take part in this research study, we will offer you a $50 Amazon gift card following 10 hours of use of the app.&nbsp;</span></p>
<p><span style="font-weight: 400;">If you wish to learn more about the results of this research you can contact Arman Aydemir arman.aydemir@colorado.edu.</span></p>
<p><br /><br /></p>
"""
