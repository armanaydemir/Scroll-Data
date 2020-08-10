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
    let batchSize = 100

    var startTime = CFAbsoluteTimeGetCurrent()
    var last_sent = CFAbsoluteTimeGetCurrent()
    
    let articleLink: String
    
    var readingSession: ReadingSession?
    var articleClosed = false
    
    var position: Int = 0
    var statesInFlight: [AbsolutePageState] = []
    var pendingStates: [AbsolutePageState] = []
    
    init(articleLink: String) {
        self.articleLink = articleLink
    }
    
    func fetchText(completion: @escaping ((_ result: Result<ReadingSession, Error>) -> Void))  {
        
        Server.Request
            .openArticle(articleID: self.articleLink,
                         UDID: UDID,
                         startTime: self.startTime*timeOffset,
                         type: AppDelegate.deviceType(),
                         version: appVersion)
            .log()
            .startRequest { (result: Result<ReadingSession, Error>) in
                switch result {
                case .success(let readingSession):
                    self.readingSession = readingSession
                case .failure:
                    break
                }
                completion(result)
        }
    }

    func submitData(content_offset: CGFloat, first_index: CGFloat, last_index: CGFloat){
        let cur:CFAbsoluteTime = CFAbsoluteTimeGetCurrent()

        pendingStates.append(AbsolutePageState(startTime: self.last_sent, duration: cur, contentOffset: content_offset, firstLine: first_index, lastLine: last_index, position: position))
        position = position + 1
        
        
        
        if pendingStates.count >= batchSize && statesInFlight.isEmpty {
            sendBatch(Array(pendingStates.prefix(batchSize)))
        }
        

        
        self.last_sent = cur
    }
    
    private func sendBatch(_ batch: [AbsolutePageState]) {
        guard let readingSession = self.readingSession else { return }
        
        pendingStates.removeAll { batch.contains($0) }
        statesInFlight.append(contentsOf: batch)
        
        Server.Request
            .submitReadingDataBatch(articleID: self.articleLink,
                                    UDID: UDID,
                                    startTime: self.startTime*timeOffset,
                                    sessionID: readingSession.sessionID,
                                    batch: batch)
            .startRequest { (result : Result<GenericResponse, Swift.Error>) in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    self.pendingStates.append(contentsOf: self.statesInFlight)
                    print(error)
                }
                self.statesInFlight.removeAll(keepingCapacity: true)
            }
    }
    
    private func sendRemainingPendingStates() {
        if !pendingStates.isEmpty {
            sendBatch(pendingStates)
        }
    }
    
    func leavingArticle() {
        sendRemainingPendingStates()
    }
    
    func closeArticle(complete: Bool) {
        guard let articleResponse = self.readingSession
            else { return }
        
        sendRemainingPendingStates()
        
        articleClosed = true
        
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
