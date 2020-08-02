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
        let data: [String:Any] = [
            "article_link": self.sessionID,
            "UDID": UDID,
            "type": AppDelegate.deviceType() ?? "",
            "version": appVersion
        ]
        
        Networking.request(headers: nil, method: "POST", fullEndpoint: serverURL+"/session_replay", body: data, completion: { data, response, error in
            if let dataExists = data, error == nil {
                do {
                    let data = try JSONSerialization.jsonObject(with: dataExists, options: .allowFragments)
                    let sessionReplay = try SessionReplayResponse(data: data)
                    completion(.success(sessionReplay))
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(ServerError.serverDisconnected))
            }
        })
    }
}

class ReadArticleViewModel {
    
    
    let timeOffset:Double = 100000000
    var startTime = CFAbsoluteTimeGetCurrent()
    var last_sent = CFAbsoluteTimeGetCurrent()
    
    var recent_first: Int?
    var recent_last: Int?
    
    let articleLink: String
    
    var articleResponse: ArticleResponse?
    
    init(articleLink: String) {
        self.articleLink = articleLink
    }
    
    func fetchText(completion: @escaping ((_ result: Result<ArticleResponse, Error>) -> Void))  {
        let data: [String:Any] = [
            "article_link": self.articleLink,
            "UDID": UDID,
            "startTime":self.startTime*timeOffset,
            "type": AppDelegate.deviceType() ?? "",
            "version":appVersion
        ]
        
        Networking.request(headers: nil, method: "POST", fullEndpoint: serverURL+"/open_article", body: data, completion: { data, response, error in
            if let dataExists = data, error == nil {
                do {
                    let data = try JSONSerialization.jsonObject(with: dataExists, options: .allowFragments)
                    let articleResponse = try ArticleResponse(data: data)
                    self.articleResponse = articleResponse
                    completion(.success(articleResponse))
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(ServerError.serverDisconnected))
            }
        })
    }

    func submitData(content_offset:CGFloat, first_index:Int, last_index:Int){
        if (self.recent_first == nil || first_index != recent_first || last_index != recent_last) {
            
            let cur:CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
            
            let data: [String: Any] = [
                "UDID": UDID,
                "article":self.articleLink,
                "startTime":self.startTime*timeOffset,
                "appeared":self.last_sent*timeOffset,
                "time": cur*timeOffset,
                "first_cell":first_index,
                "last_cell":last_index,
                "previous_first_cell":self.recent_first ?? "",
                "previous_last_cell":self.recent_last ?? "",
                "content_offset":content_offset ]
            
            Networking.request(headers: nil, method: "POST", fullEndpoint: serverURL+"/submit_data", body: data) {
                data, response, error in

                if let e = error { print(e) }
            }
            
            self.last_sent = cur
            self.recent_last = last_index
            self.recent_first = first_index
            
            print(data)
        }
    }
    
    func closeArticle(complete: Bool) {
        guard let a = UIApplication.shared.delegate as? AppDelegate,
            let articleResponse = self.articleResponse
            else { return }
        
        let data: [String: Any] = [
            "UDID": UDID,
            "startTime": self.startTime*timeOffset,
            "article": articleResponse.article.info.url,
            "time": CFAbsoluteTimeGetCurrent()*timeOffset,
            "session_id": articleResponse.sessionID,
            "complete": complete,
            "portrait": a.orientation.isPortrait
        ]
        
        print(data)
        
        Networking.request(headers: nil, method: "POST", fullEndpoint: serverURL+"/close_article", body: data) { data, response, error in
            if let e = error { print(e) }
        }
    }
}


enum ServerError: String, Error {
    case serverDisconnected
}
