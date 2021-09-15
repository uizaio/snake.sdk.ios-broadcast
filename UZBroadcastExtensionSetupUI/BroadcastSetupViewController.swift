//
//  BroadcastSetupViewController.swift
//  UZBroadcastExtensionSetupUI
//
//  Created by Nam Kennic on 9/10/21.
//  Copyright © 2021 Uiza. All rights reserved.
//

import ReplayKit

class BroadcastSetupViewController: UIViewController {

    // Call this method when the user has finished interacting with the view controller and a broadcast stream can start
    func userDidFinishSetup() {
        // URL of the resource where broadcast can be viewed that will be returned to the application
		let urlPath = "rtmp://a.rtmp.youtube.com/live2"
        let broadcastURL = URL(string: urlPath)
        
        // Dictionary with setup information that will be provided to broadcast extension when broadcast is started
		let setupInfo: [String : NSCoding & NSObjectProtocol] = ["urlPath": urlPath as NSCoding & NSObjectProtocol,
																 "streamKey": "ftbg-1rw5-8abs-bkfp-d3ya" as NSCoding & NSObjectProtocol]
        
        // Tell ReplayKit that the extension is finished setting up and can begin broadcasting
        self.extensionContext?.completeRequest(withBroadcast: broadcastURL!, setupInfo: setupInfo)
    }
    
    func userDidCancelSetup() {
        let error = NSError(domain: "YouAppDomain", code: -1, userInfo: nil)
        // Tell ReplayKit that the extension was cancelled by the user
        self.extensionContext?.cancelRequest(withError: error)
    }
}
