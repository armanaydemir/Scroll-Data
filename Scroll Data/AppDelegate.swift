//
//  AppDelegate.swift
//  Scroll Data
//
//  Created by Aydemir on 11/26/18.
//  Copyright © 2018 Arman Aydemir. All rights reserved.
//

import UIKit


let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"

let UDID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"

let baseFont: UIFont = UIFont.init(name: "Times New Roman", size: UIFont.systemFontSize)!



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var deviceType: String?
    var homeViewController: UIViewController? = nil
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
    
    class func deviceType() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let deviceType = Mirror(reflecting: systemInfo.machine).children.reduce("") { identifier, element in
            guard let value = element.value as? Int8,
                value != 0
                else { return identifier }
            
            return (identifier) + String(UnicodeScalar(UInt8(value)))
        }
        
        return deviceType
    }
        
}
