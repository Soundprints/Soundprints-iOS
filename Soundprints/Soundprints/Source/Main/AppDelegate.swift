//
//  AppDelegate.swift
//  Soundprints
//
//  Created by Svit Zebec on 28/11/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import FBSDKLoginKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        Fabric.with([Crashlytics.self])
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any] = [:]) -> Bool {
        if let sourceApplication = options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String {
            let handled = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, sourceApplication: sourceApplication, annotation: options[UIApplicationOpenURLOptionsKey.annotation])
            return handled
        }
        
        return false
    }


}

