//
//  UserInfo.swift
//  Scroll Data
//
//  Created by Deniz Aydemir on 8/28/20.
//  Copyright © 2020 Arman Aydemir. All rights reserved.
//

import UIKit

class UserInfo {
    
    enum Key: String {
        case agreed_to_terms
    }
    
    var agreedToTerms: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Key.agreed_to_terms.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Key.agreed_to_terms.rawValue)
        }
    }
    
    
    init() {}

}
