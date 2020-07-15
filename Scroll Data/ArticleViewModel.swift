//
//  ArticleViewModel.swift
//  Scroll Data
//
//  Created by Aydemir on 11/26/18.
//  Copyright © 2018 Arman Aydemir. All rights reserved.
//

import UIKit

class ArticleViewModel: NSObject {
//    let url = "157.245.227.103"
    let url = "localhost"
    let version = "v0.3.1"
    let UDID = UIDevice.current.identifierForVendor!.uuidString
    let timeOffset:Double = 100000000
    var startTime = CFAbsoluteTimeGetCurrent()
    var last_sent = CFAbsoluteTimeGetCurrent()
    var deviceType: String?
    var session_id: String?
    var articleLink: String?
    
    var recent_first: Int?
    var recent_last: Int?
    
    
    var lines: Array<String>?
    
    
    init(articleLink: String) {
        self.articleLink = articleLink
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        self.deviceType = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 , value != 0 else { return identifier }
            return identifier! + String(UnicodeScalar(UInt8(value)))
        }
    }
    
    func fetchText(completion: @escaping ([String:Any], String?) -> Void)  {
        let data: [String:Any] = [
            "article_link":self.articleLink ?? "",
            "UDID":self.UDID,
            "startTime":self.startTime*timeOffset,
            "type":self.deviceType ?? "",
            "version":self.version]
        
        Networking.request(headers: nil, method: "POST", fullEndpoint: "http://"+url+":22364/session_replay", body: data, completion: { data, response, error in
            if let dataExists = data, error == nil {
                do {
                    if let data = try JSONSerialization.jsonObject(with: dataExists, options: .allowFragments) as? [String : Any] {
                        //self.session_id = paragraphs[0]
                        //paragraphs.remove(at: 0)
                        completion(data, nil)
                    } else {
                        completion([:], "invalid json")
                    }
                }catch _{
                    completion([:], "invalid json")
                }
            }else{
                completion([:], "server disconnect")
            }
        })
    }
    
    
    
    func submitData(content_offset:CGFloat, first_index:Int, last_index:Int){
        if (self.recent_first == nil || first_index != recent_first || last_index != recent_last) {
            let cur:CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
            
            let data: [String: Any] = [
                "UDID":self.UDID,
                "article":self.articleLink ?? "",
                "startTime":self.startTime*timeOffset,
                "appeared":self.last_sent*timeOffset,
                "time": cur*timeOffset,
                "first_cell":first_index,
                "last_cell":last_index,
                "previous_first_cell":self.recent_first ?? "",
                "previous_last_cell":self.recent_last ?? "",
                "content_offset":content_offset ]
            
//            Networking.request(headers: nil, method: "POST", fullEndpoint: "http://"+url+":22364/submit_data", body: data, completion:  {
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
            "UDID": self.UDID,
            "startTime": self.startTime*timeOffset,
            "article": self.articleLink ?? "",
            "time": CFAbsoluteTimeGetCurrent()*timeOffset,
            "session_id": self.session_id ?? "",
            "complete": complete,
            "word_splits": wordIndicies,
            "character_splits": characterIndicies,
            "content": content,
            "portrait": a.orientation.isPortrait
        ]
        
//        Networking.request(headers: nil, method: "POST", fullEndpoint: "http://"+url+":22364/close_article", body: data, completion:  { data, response, error in
//            if let e = error {print(e)}
//        })
    }
}
