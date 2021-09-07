//
//  UZScreenBroadcast.swift
//  UZBroadcast
//
//  Created by Nam Kennic on 3/21/20.
//  Copyright © 2020 Uiza. All rights reserved.
//

import UIKit
import HaishinKit
import ReplayKit

/**
This class helps you to initialize a screen broadcast session
*/
@available(iOS 13.0, *)
public class UZScreenBroadcast {
	/// `true` if broadcasting
	public fileprivate(set)var isBroadcasting = false
	
	@available(iOS 13.0, *)
	/// Turn on or off microphone
	public var isMicrophoneEnabled: Bool {
		get { screenRecorder.isMicrophoneEnabled }
		set { screenRecorder.isMicrophoneEnabled = newValue }
	}
	
	@available(iOS 13.0, *)
	/// Turn on or off camera
	public var isCameraEnabled: Bool {
		get { screenRecorder.isCameraEnabled }
		set { screenRecorder.isCameraEnabled = newValue }
	}
	
	@available(iOS 13.0, *)
	/// Current camera preview view
	public var cameraPreviewView: UIView? {
		return screenRecorder.cameraPreviewView
	}
	
	@available(iOS 13.0, *)
	/// Current camera position
	public var cameraPosition: RPCameraPosition {
		return screenRecorder.cameraPosition
	}
	
	@available(iOS 13.0, *)
	/// `true` if the screen is recording
	public var isRecording: Bool {
		return screenRecorder.isRecording
	}
	
	/// Current broadcast configuration
	public fileprivate(set) var config: UZBroadcastConfig!
	let screenRecorder = RPScreenRecorder.shared()
	
	
	/**
	Always call this first to prepare broadcasting with a configuration
	- parameter config: Broadcast configuration
	*/
	@discardableResult
	public func prepareForBroadcast(config: UZBroadcastConfig) {
		self.config = config
	}
	
	/**
	Start screen broadcasting
	- parameter broadcastURL: `URL` of broadcast
	- parameter streamKey: Stream Key
	- parameter completionHandler: Block called when completed, returns `Error` if occured
	*/
	public func startBroadcast(broadcastURL: URL, streamKey: String, completionHandler: ((Error?) -> Void)? = nil) {
		isBroadcasting = true
		
//		let stream = LFLiveStreamInfo()
//		stream.url = broadcastURL.appendingPathComponent(streamKey).absoluteString
////		session.running = true
//		session.startLive(stream)
		
//		screenRecorder.cameraPosition = config.cameraPosition == .front ? .front : .back
		screenRecorder.isCameraEnabled = false
		screenRecorder.startCapture(handler: { (sampleBuffer, bufferType, error) in
//			if bufferType == .audioMic || bufferType == .audioApp {
//				self.session.pushAudioBuffer(sampleBuffer)
//			}
//			else {
//				self.session.pushVideoBuffer(sampleBuffer)
//			}
		}, completionHandler: completionHandler)
	}
	
	/**
	Stop screen broadcasting
	- parameter handler: Block called when completed, returns `Error` if occured
	*/
	public func stopBroadcast(handler: ((Error?) -> Void)? = nil) {
//		session.stopLive()
//		session.running = false
		screenRecorder.stopCapture(handler: handler)
		isBroadcasting = false
	}
	
}
