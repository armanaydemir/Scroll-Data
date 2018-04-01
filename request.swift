//
//  request.swift
//  Scroll Data
//
//  Created by Arman Aydemir on 11/25/17.
//  Copyright © 2017 Arman Aydemir. All rights reserved.
//

import Foundation

func + <K,V>(left: Dictionary<K,V>, right: Dictionary<K,V>) -> Dictionary<K,V> {
    var map = Dictionary<K,V>()
    for (k, v) in left {
        map[k] = v
    }
    for (k, v) in right {
        map[k] = v
    }
    return map
}

public class Networking:NSObject {

    public class func request(headers: [String : String]?, method: String, fullEndpoint: String, body: [String : Any]?, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        print(fullEndpoint)
        let defaultSession = URLSession(configuration: URLSessionConfiguration.default)
        defaultSession.configuration.httpCookieAcceptPolicy = .always
        
        let url: URL
        if let body = body, method == "GET" {
            let getParams = body.reduce("") { result, element in "\(result)\(result.count > 0 ? "&" : "")\(element.key)=\(element.value)" }
            url = URL(string: "\(fullEndpoint)?\(getParams)")!
        } else {
            url = URL(string: fullEndpoint)!
        }
        var request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 30)
        request.allHTTPHeaderFields = (headers ?? [:]) + [ "content-type" : "application/json"]
        request.httpMethod = method
        if let body = body, method != "GET" {
            request.httpBody = try! JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        }
        
        print(request.url!)
        defaultSession.dataTask(with: request, completionHandler: completion).resume()
    }

    public class func dictionary(fromData data: Data?) -> [String : AnyObject]? {
        if let data = data {
            return (try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)) as? [String : AnyObject]
        } else {
            return nil
        }
    }    
}
