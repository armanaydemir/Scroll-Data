//
//  AppDelegate.swift
//  Scroll Data
//
//  Created by Aydemir on 11/26/18.
//  Copyright © 2018 Arman Aydemir. All rights reserved.
//

import UIKit


let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var autoRotate: Bool = true
    var orientation: UIDeviceOrientation = UIDeviceOrientation.portrait
    
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
        
}
