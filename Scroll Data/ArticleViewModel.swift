//
//  ArticleViewModel.swift
//  Scroll Data
//
//  Created by Aydemir on 11/26/18.
//  Copyright © 2018 Arman Aydemir. All rights reserved.
//

import UIKit

class SessionReplayViewModel: NSObject {
    
    let sessionID: String

    init(sessionID: String) {
        self.sessionID = sessionID
    }
    
    func fetchSessionReplay(completion: @escaping ((_ result: Result<PlayableSession, Error>) -> Void))  {
        Server.Request
            .openSession(sessionID: self.sessionID, UDID: UDID, type: AppDelegate.deviceType(), version: appVersion)
            .startRequest { (result: Result<Session, Swift.Error>) in
                
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let session):
                    let states = session.states
                    
                    guard let firstState = states.first,
                        let lastState = states.last
                        else { completion(.failure(ViewModelError.emptyData)); return  }
                    
                    let startTime = firstState.startTime
                    let endTime = lastState.startTime
                    let relativeStates = states.map { RelativePageState(absolutePageState: $0,
                                                                        sessionStartTime: startTime,
                                                                        totalSessionDuration: endTime - startTime) }

                    let playableSession = PlayableSession(states: relativeStates, startTime: startTime, endTime: endTime, article: session.article, maxLines: session.maxLines)
                    
                    completion(.success(playableSession))
                }
            }
    }
}

public struct PlayableSession {
    let states: [RelativePageState]
    let startTime: TimeInterval
    let endTime: TimeInterval
    
    let article: Article
    let maxLines: Int
}

public struct RelativePageState {
    public let relativeStartTime: Double
    public let relativeDuration: Double
    
    public let contentOffset: CGFloat
    
    public let firstLine: CGFloat
    public let lastLine: CGFloat

    
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


class ReadArticleViewModel {
    
    
    let timeOffset:Double = 100000000

    var startTime = CFAbsoluteTimeGetCurrent()
    var last_sent = CFAbsoluteTimeGetCurrent()
    
    let articleLink: String
    
    var articleResponse: OpenArticle?
    
    init(articleLink: String) {
        self.articleLink = articleLink
    }
    
    func fetchText(completion: @escaping ((_ result: Result<OpenArticle, Error>) -> Void))  {
        
        Server.Request
            .openArticle(articleID: self.articleLink,
                         UDID: UDID,
                         startTime: self.startTime*timeOffset,
                         type: AppDelegate.deviceType(),
                         version: appVersion)
            .log()
            .startRequest(completion: completion)
    }

    func submitData(content_offset: CGFloat, first_index: CGFloat, last_index: CGFloat){
        let cur:CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
        
        Server.Request
            .submitReadingData(articleID: self.articleLink,
                               UDID: UDID,
                               startTime: self.startTime*timeOffset,
                               appeared: self.last_sent*timeOffset,
                               time: cur*timeOffset,
                               firstCell: first_index,
                               lastCell: last_index,
                               contentOffset: content_offset)
            .log()
            .startRequest { (result : Result<GenericResponse, Swift.Error>) in
                if case .failure = result {
                    //print(e)
                    //suppressing error for now because empty json being returned from server
                }
            }
        
        self.last_sent = cur
    }
    
    func closeArticle(complete: Bool) {
        guard let articleResponse = self.articleResponse
            else { return }
        
        Server.Request
            .closeArticle(articleID: articleResponse.article.info.url,
                          UDID: UDID,
                          startTime: self.startTime*timeOffset,
                          time: CFAbsoluteTimeGetCurrent()*timeOffset,
                          sessionID: articleResponse.sessionID,
                          complete: complete,
                          isPortrait: true)
            .startRequest { (result : Result<GenericResponse, Swift.Error>) in
                if case .failure(let e) = result { print(e) }
            }
    }
    
    @objc func logEvent(notification: Notification) {
        
        let eventType: String
        
        switch notification.name {
        case UIApplication.willResignActiveNotification:
            eventType = "obstructed"
        case UIApplication.didBecomeActiveNotification:
            eventType = "visible"
        case UIApplication.didEnterBackgroundNotification:
            eventType = "background"
        case UIApplication.willEnterForegroundNotification:
            eventType = "foreground"
        default:
            print("unknown notification")
            return
        }
        
        Server.Request
            .submitEvent(articleID: self.articleLink,
                         UDID: UDID,
                         startTime: self.startTime,
                         time: CFAbsoluteTimeGetCurrent()*timeOffset,
                         eventType: eventType)
            .log()
            .startRequest { (result: Result<GenericResponse, Error>) in
                    if case .failure(let error) = result {
                        print(error)
                    }
                }
    }
}


enum ViewModelError: String, Error {
    case emptyData
}
