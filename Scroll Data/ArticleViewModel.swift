//
//  ArticleViewModel.swift
//  Scroll Data
//
//  Created by Aydemir on 11/26/18.
//  Copyright © 2018 Arman Aydemir. All rights reserved.
//

import UIKit

class SessionReplayViewModel: NSObject {
    
    var articleLink: String

    init(articleLink: String) {
        self.articleLink = articleLink
    }
    
    func fetchSessionReplay(completion: @escaping ((_ result: Result<SessionReplayResponse, Error>) -> Void))  {
        let data: [String:Any] = [
            "article_link":self.articleLink ?? "",
            "UDID": UDID,
            //"startTime":self.startTime*timeOffset,
            "type": AppDelegate.deviceType() ?? "",
            "version":appVersion]
        
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
    var deviceType: String?
    var session_id: String?
    var articleLink: String
    
    var recent_first: Int?
    var recent_last: Int?
    
    
    var lines: Array<String>?
    
    init(articleLink: String) {
        self.articleLink = articleLink
        
    }
    
    func fetchText(completion: @escaping ((_ result: Result<SessionReplayResponse, Error>) -> Void))  {
        let data: [String:Any] = [
            "article_link":self.articleLink,
            "UDID": UDID,
            "startTime":self.startTime*timeOffset,
            "type":self.deviceType ?? "",
            "version":appVersion]
        
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
            
//            Networking.request(headers: nil, method: "POST", fullEndpoint: serverURL+"/submit_data", body: data, completion:  {
//                data, response, error in
//
//                if let e = error {print(e)}
//            })
            
            self.last_sent = cur
            self.recent_last = last_index
            self.recent_first = first_index
        }
    }
    
    func closeArticle(content: Array<Dictionary<String, Any>>, wordIndicies: Array<Int>, characterIndicies: Array<Int>, complete:Bool){
        guard let a = UIApplication.shared.delegate as? AppDelegate else {return}
        let data: [String: Any] = [
            "UDID": UDID,
            "startTime": self.startTime*timeOffset,
            "article": self.articleLink,
            "time": CFAbsoluteTimeGetCurrent()*timeOffset,
            "session_id": self.session_id ?? "",
            "complete": complete,
            "word_splits": wordIndicies,
            "character_splits": characterIndicies,
            "content": content,
            "portrait": a.orientation.isPortrait
        ]
        
//        Networking.request(headers: nil, method: "POST", fullEndpoint: serverURL+"/close_article", body: data, completion:  { data, response, error in
//            if let e = error {print(e)}
//        })
    }
}


enum ServerError: String, Error {
    case serverDisconnected
}
