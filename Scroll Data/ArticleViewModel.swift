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
    
    func fetchSessionReplay(completion: @escaping ((_ result: Result<SessionReplayResponse, Error>) -> Void))  {        
        Server.Request
            .openSession(sessionID: self.sessionID, UDID: UDID, type: AppDelegate.deviceType(), version: appVersion)
            .startRequest(completion: completion)
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
        guard let a = UIApplication.shared.delegate as? AppDelegate,
            let articleResponse = self.articleResponse
            else { return }
        
        Server.Request
            .closeArticle(articleID: articleResponse.article.info.url,
                          UDID: UDID,
                          startTime: self.startTime*timeOffset,
                          time: CFAbsoluteTimeGetCurrent()*timeOffset,
                          sessionID: articleResponse.sessionID,
                          complete: complete,
                          isPortrait: a.orientation.isPortrait)
            .startRequest { (result : Result<GenericResponse, Swift.Error>) in
                if case .failure(let e) = result { print(e) }
            }
    }
}


enum ServerError: String, Error {
    case serverDisconnected
}
