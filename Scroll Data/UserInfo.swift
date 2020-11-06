//
//  UserInfo.swift
//  Scroll Data
//
//  Created by Deniz Aydemir on 8/28/20.
//  Copyright © 2020 Arman Aydemir. All rights reserved.
//

import UIKit

class UserInfo {
    
    static let shared = UserInfo()
    
    enum Key: String {
        case agreed_to_terms
        case email
    }
    
    var agreedToTerms: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Key.agreed_to_terms.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Key.agreed_to_terms.rawValue)
        }
    }
    
    var email: String? {
        get {
            return UserDefaults.standard.string(forKey: Key.email.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Key.email.rawValue)
        }
    }
    
    private var settings: Settings?
    
    private init() {}
    
    
    func fetchSettings(completion: @escaping (_ settings: Settings) -> Void) {
        if let settings = self.settings {
            completion(settings)
        } else {
            Server.Request.settings.startRequest { (result: Result<Settings, Swift.Error>) in
                switch result {
                case .success(let settings):
                    self.settings = settings
                    completion(settings)
                case .failure(let error):
                    print(error)
                    let settings = Settings()
                    self.settings = settings
                    completion(settings) //return the defaults if there's an issue
                }
            }
        }
    }

}
