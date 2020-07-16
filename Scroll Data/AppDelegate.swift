//
//  AppDelegate.swift
//  Scroll Data
//
//  Created by Aydemir on 11/26/18.
//  Copyright © 2018 Arman Aydemir. All rights reserved.
//

import UIKit


let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"

let serverURL = "http://157.245.227.103:22364"
//let serverURL = "http://localhost:22364"

let UDID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"

let baseFont: UIFont = UIFont.init(name: "Times New Roman", size: UIFont.systemFontSize)!


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var autoRotate: Bool = true
    var orientation: UIDeviceOrientation = UIDeviceOrientation.portrait
    var deviceType: String?
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        

        
        if(!UIDevice.current.model.lowercased().contains("ipad")){
            return UIInterfaceOrientationMask.portrait
        }
        if(self.autoRotate){
            return UIInterfaceOrientationMask.all
        }else {
            if(self.orientation.isPortrait){
                return .portrait
            }else{
                return .landscape
            }
        }
    }
    
    class func deviceType() -> String? {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        return Mirror(reflecting: systemInfo.machine).children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return (identifier ?? "") + String(UnicodeScalar(UInt8(value)))
        }
        
    }
        
}
