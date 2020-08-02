//
//  Server.swift
//  Scroll Data
//
//  Created by Deniz Aydemir on 8/2/20.
//  Copyright © 2020 Arman Aydemir. All rights reserved.
//

import UIKit

let serverURL = "http://157.245.227.103:22364/"
//let serverURL = "http://localhost:22364/"

struct Server {
    enum RequestType: String {
        case get = "GET"
        case post = "POST"
    }
    
    enum Request {
        
        case settings
        case articles
        case sessions
        case openArticle(articleID: String, UDID: String, startTime: Double, type: String, version: String)
        case submitReadingData(articleID: String, UDID: String, startTime: Double, appeared: Double, time: Double, firstCell: Int, lastCell: Int, contentOffset: CGFloat, previousFirstCell: Int?, previousLastCell: Int?)
        case closeArticle(articleID: String, UDID: String, startTime: Double, time: Double, sessionID: String, complete: Bool, isPortrait: Bool)
        case openSession(sessionID: String, UDID: String, type: String, version: String)
        
        func startRequest(completion: @escaping Networking.RequestCompletion) {
            Networking.request(headers: Server.headers(), method: self.type().rawValue, fullEndpoint: self.endpoint(), body: self.parameters(), completion: completion)
        }
        
        func log() -> Request {
            print("\(self.endpoint())\n\(self.type())\n\(self.parameters())")
            return self
        }
        
        func endpoint() -> String {
            let endpoint: String
            switch self {
            case .settings:
                endpoint = "settings"
            case .articles:
                endpoint = "articles"
            case .sessions:
                endpoint = "sessions"
            case .openArticle:
                endpoint = "open_article"
            case .submitReadingData:
                endpoint = "submit_data"
            case .closeArticle:
                endpoint = "close_article"
            case .openSession:
                endpoint = "session_replay"
            }
            return serverURL + endpoint
        }
        
        func type() -> RequestType {
            switch self {
            case .settings, .articles, .sessions:
                return .get
            case .openArticle, .openSession, .submitReadingData, .closeArticle:
                return .post
            }
        }
        
        func parameters() -> [String : Any] {
            let params: [String : Any]
            
            switch self {
            case .settings, .articles, .sessions:
                return [:]
            case .openArticle(articleID: let articleID, UDID: let UDID, startTime: let startTime, type: let type, version: let version):
                params = [
                    "article_link": articleID,
                    "UDID": UDID,
                    "startTime": startTime,
                    "type": type,
                    "version": version
                ]
            case .submitReadingData(articleID: let articleID, UDID: let UDID, startTime: let startTime, appeared: let appeared, time: let time, firstCell: let firstCell, lastCell: let lastCell, contentOffset: let contentOffset, previousFirstCell: let previousFirstCell, previousLastCell: let previousLastCell):
                params = [  "UDID": UDID,
                            "article": articleID,
                            "startTime": startTime,
                            "appeared": appeared,
                            "time": time,
                            "first_cell": firstCell,
                            "last_cell": lastCell,
                            "previous_first_cell": previousFirstCell ?? "",
                            "previous_last_cell": previousLastCell ?? "",
                            "content_offset": contentOffset ]
                
            case .closeArticle(articleID: let articleID, UDID: let UDID, startTime: let startTime, time: let time, sessionID: let sessionID, complete: let complete, isPortrait: let isPortrait):
                params = [  "UDID": UDID,
                            "startTime": startTime,
                            "article": articleID,
                            "time": time,
                            "session_id": sessionID,
                            "complete": complete,
                            "portrait": isPortrait]
                
            case .openSession(sessionID: let sessionID, UDID: let UDID, type: let type, version: let version):
                params = [
                     "article_link": sessionID,
                     "UDID": UDID,
                     "type": type,
                     "version": version
                 ]
            }
            
            return params
        }
    }
    
    static func headers() -> [String : String] {
        let headers: [String : String] = [ "X-APP-VERSION" : appVersion,
                                           "X-UDID" : UDID,
                                           "X-DEVICE-TYPE" : AppDelegate.deviceType() ?? "",
                                           "X-OS-VERSION" : UIDevice.current.systemVersion,
                                           "X-OS-NAME" : UIDevice.current.systemName]
        
        return headers
    }
}


