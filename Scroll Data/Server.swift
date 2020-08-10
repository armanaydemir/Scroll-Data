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
        case submitReadingDataBatch(articleID: String,
            UDID: String,
            startTime: Double,
            sessionID: String,
            batch: [AbsolutePageState])
        case closeArticle(articleID: String, UDID: String, startTime: Double, time: Double, sessionID: String, complete: Bool, isPortrait: Bool)
        case openSession(sessionID: String, UDID: String, type: String, version: String)
        case submitEvent(articleID: String,
            UDID: String,
            startTime: Double,
            time: Double,
            eventType: String)
        
        typealias Completion<T: JSONParseable> = (Result<T, Swift.Error>) -> Void
        
        func startRequest<T: JSONParseable>(completion: @escaping Completion<T>) {
            Networking.request(headers: Server.headers(), method: self.type().rawValue, fullEndpoint: self.endpoint(), body: self.parameters()) { data, response, error in
                
                if let error = error {
                    completion(.failure(error))
                } else if let data = data, error == nil {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                        let object = try T(data: json)
                        completion(.success(object))
                    } catch let err {
                        completion(.failure(err))
                    }
                } else {
                    completion(.failure(Error.unknown))
                }
            }
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
            case .submitReadingDataBatch:
                endpoint = "submit_data_batched"
            case .closeArticle:
                endpoint = "close_article"
            case .openSession:
                endpoint = "session_replay"
            case .submitEvent:
                endpoint = "submit_event"
            }
            return serverURL + endpoint
        }
        
        func type() -> RequestType {
            switch self {
            case .settings, .articles, .sessions:
                return .get
            case .openArticle, .openSession, .submitReadingDataBatch, .closeArticle, .submitEvent:
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
            case .submitReadingDataBatch(articleID: let articleID, UDID: let UDID, startTime: let startTime, sessionID: let sessionID, batch: let batch):
                params = [  "UDID": UDID,
                            "article": articleID,
                            "startTime": startTime,
                            "session_id": sessionID,
                            "data" : batch.map { $0.toDictionary() }]
                
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
            case .submitEvent(let articleID, let UDID, let startTime, let time, let eventType):
                params = [  "UDID": UDID,
                            "article": articleID,
                            "startTime": startTime,
                            "time": time,
                            "event_type": eventType ]
                
            }
            
            return params
        }
    }
    
    static func headers() -> [String : String] {
        let headers: [String : String] = [ "X-APP-VERSION" : appVersion,
                                           "X-UDID" : UDID,
                                           "X-DEVICE-TYPE" : AppDelegate.deviceType(),
                                           "X-OS-VERSION" : UIDevice.current.systemVersion,
                                           "X-OS-NAME" : UIDevice.current.systemName]
        
        return headers
    }
    
    enum Error: String, Swift.Error {
        case unknown
    }
}

struct GenericResponse: JSONParseable {
    let json: Any?
    
    init(data: Any?) throws {
        self.json = data
    }
}

protocol JSONParseable {
    init(data: Any?) throws
}


extension Array: JSONParseable where Element: JSONParseable {
    init(data: Any?) throws {
        guard let data = data as? [Any]
            else { throw ModelError.errorParsingJSON }
        
        self = data.compactMap { try? Element.init(data: $0) }
    }
}
