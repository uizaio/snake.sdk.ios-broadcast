//
//  SampleHandler.swift
//  UZBroadcastExtension
//
//  Created by Nam Kennic on 9/10/21.
//  Copyright © 2021 Uiza. All rights reserved.
//

import ReplayKit
import UZBroadcast

class SampleHandler: RPBroadcastSampleHandler {
	let broadcaster = UZScreenBroadcast()
	
	var videoResolution: UZVideoResolution = ._720
	var videoBitrate: UZVideoBitrate = ._4000Kbps
	var videoFPS: UZVideoFPS = ._30fps
	
	var audioBitrate: UZAudioBitrate = ._128Kbps
	var audioSampleRate: UZAudioSampleRate = ._44_1khz
	
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
		guard let urlPath = setupInfo?["urlPath"] as? String, let streamKey = setupInfo?["streamKey"] as? String else { return }
		
		let config = UZBroadcastConfig(cameraPosition: .back, videoResolution: videoResolution, videoBitrate: videoBitrate, videoFPS: videoFPS, audioBitrate: audioBitrate, audioSampleRate: audioSampleRate, adaptiveBitrate: true, autoRotate: false)
		broadcaster.prepareForBroadcast(config: config)
		broadcaster.isCameraEnabled = false
		broadcaster.isMicrophoneEnabled = false
		broadcaster.startBroadcast(broadcastURL: URL(string: urlPath)!, streamKey: streamKey) { error in
			print("Error: \(String(describing: error))")
		}
    }
    
    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
    }
    
    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
    }
    
    override func broadcastFinished() {
        // User has requested to finish the broadcast.
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
		broadcaster.processSampleBuffer(sampleBuffer, with: sampleBufferType)
    }
}
