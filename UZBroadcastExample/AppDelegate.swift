//
//  AppDelegate.swift
//  UZBroadcastExample
//
//  Created by Nam Kennic on 3/17/20.
//  Copyright © 2020 Uiza. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		window = UIWindow(frame: UIScreen.main.bounds)
		if #available(iOS 13.0, *) {
			window?.rootViewController = ViewController()
		} else {
			// Fallback on earlier versions
		}
		window?.makeKeyAndVisible()
		
		return true
	}
	
}

