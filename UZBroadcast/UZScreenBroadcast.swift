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
import VideoToolbox

/**
This class helps you to initialize a screen broadcast session
*/
@available(iOS 13.0, *)
public class UZScreenBroadcast {
	/// Current broadcastURL
	public private(set) var broadcastURL: URL?
	/// Current streamKey
	public private(set) var streamKey: String?
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
	
	/// Set active camera
	public var cameraPosition: UZCameraPosition {
		get { screenRecorder.cameraPosition == .front ? .front : .back }
		set {
			guard cameraPosition != newValue else { return }
			screenRecorder.cameraPosition = newValue == .front ? .front : .back
		}
	}
	
	@available(iOS 13.0, *)
	/// `true` if the screen is recording
	public var isRecording: Bool {
		return screenRecorder.isRecording
	}
	
	/// Video Bitrate
	public var videoBitrate: UInt32? {
		get { rtmpStream.videoSettings[.bitrate] as? UInt32 }
		set { rtmpStream.videoSettings[.bitrate] = newValue }
	}
	/// Video FPS settings. To get actual FPS, use currentFPS
	public var videoFPS: UInt? {
		get { rtmpStream.captureSettings[.fps] as? UInt }
		set { rtmpStream.captureSettings[.fps] = newValue }
	}
	/// Current FPS of the stream
	public var currentFPS: UInt16 {
		get { rtmpStream.currentFPS }
	}
	/// Audio Bitrate
	public var audioBitrate: UInt32? {
		get { rtmpStream.audioSettings[.bitrate] as? UInt32 }
		set { rtmpStream.audioSettings[.bitrate] = newValue }
	}
	/// Audio SampleRate
	public var audioSampleRate: UInt32? {
		get { rtmpStream.audioSettings[.sampleRate] as? UInt32 }
		set { rtmpStream.audioSettings[.sampleRate] = newValue }
	}
	
	/// Current broadcast configuration
	public fileprivate(set) var config: UZBroadcastConfig! {
		didSet {
			cameraPosition = config.cameraPosition
			videoBitrate = config.videoBitrate.value()
			videoFPS = config.videoFPS.rawValue
			audioBitrate = config.audioBitrate.rawValue
			audioSampleRate = config.audioSampleRate.rawValue
			
//			if let orientation = DeviceUtil.videoOrientation(by: UIApplication.shared.statusBarOrientation) {
//				rtmpStream.orientation = orientation
//			}
			
			rtmpStream.orientation = .portrait
			rtmpStream.videoSettings = [
				.width: config.videoResolution.videoSize.width,
				.height: config.videoResolution.videoSize.height,
				.scalingMode: ScalingMode.normal
			]
		}
	}
	private var rtmpConnection = RTMPConnection()
	internal lazy var rtmpStream = RTMPStream(connection: rtmpConnection)
	let screenRecorder = RPScreenRecorder.shared()
	
	public init() {}
	
	/**
	Always call this first to prepare broadcasting with a configuration
	- parameter config: Broadcast configuration
	*/
	@discardableResult
	public func prepareForBroadcast(config: UZBroadcastConfig) -> RTMPStream {
		self.config = config
		return rtmpStream
	}
	
	/**
	Start screen broadcasting
	- parameter broadcastURL: `URL` of broadcast
	- parameter streamKey: Stream Key
	- parameter completionHandler: Block called when completed, returns `Error` if occured
	*/
	public func startBroadcast(broadcastURL: URL, streamKey: String, completionHandler: ((Error?) -> Void)? = nil) {
		guard isBroadcasting == false else { return }
		self.broadcastURL = broadcastURL
		self.streamKey = streamKey
		
		openConnection()
		
		screenRecorder.isCameraEnabled = false
		screenRecorder.startCapture(handler: { (sampleBuffer, bufferType, error) in
			self.processSampleBuffer(sampleBuffer, with: bufferType)
		}, completionHandler: completionHandler)
		
//		#if os(macOS)
//		rtmpStream.attachScreen(AVCaptureScreenInput(displayID: CGMainDisplayID()))
//		#else
//		rtmpStream.attachScreen(ScreenCaptureSession(shared: UIApplication.shared))
//		#endif
	}
	
	public func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
		switch sampleBufferType {
			case .video:
				if let description = CMSampleBufferGetFormatDescription(sampleBuffer) {
					let dimensions = CMVideoFormatDescriptionGetDimensions(description)
					self.rtmpStream.videoSettings = [
						.width: dimensions.width,
						.height: dimensions.height,
						.profileLevel: kVTProfileLevel_H264_Baseline_AutoLevel
					]
				}
				self.rtmpStream.appendSampleBuffer(sampleBuffer, withType: .video)
				
			case .audioMic, .audioApp:
				self.rtmpStream.appendSampleBuffer(sampleBuffer, withType: .audio)
				
			@unknown default:
				break
		}
	}
	
	private func openConnection() {
		guard broadcastURL != nil, streamKey != nil else { return }
		isBroadcasting = true
//		UIApplication.shared.isIdleTimerDisabled = true
		
		rtmpConnection.addEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
		rtmpConnection.addEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
		rtmpConnection.connect(broadcastURL!.absoluteString)
	}
	
	private func closeConnection() {
		rtmpConnection.close()
		rtmpConnection.removeEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
		rtmpConnection.removeEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
	}
	
	
	/**
	Stop screen broadcasting
	- parameter handler: Block called when completed, returns `Error` if occured
	*/
	public func stopBroadcast(handler: ((Error?) -> Void)? = nil) {
		screenRecorder.stopCapture(handler: handler)
		closeConnection()
		isBroadcasting = false
	}
	
	// MARK: -
	
	var retryCount = 0
	var maxRetryCount = 5
	
	@objc private func rtmpStatusHandler(_ notification: Notification) {
		let e = Event.from(notification)
		guard let data: ASObject = e.data as? ASObject, let code: String = data["code"] as? String else { return }
		print("status: \(e)")
		
		switch code {
			case RTMPConnection.Code.connectSuccess.rawValue:
				retryCount = 0
				rtmpStream.publish(streamKey!)
				
			case RTMPConnection.Code.connectFailed.rawValue, RTMPConnection.Code.connectClosed.rawValue:
				guard retryCount <= maxRetryCount else { return }
				Thread.sleep(forTimeInterval: pow(2.0, Double(retryCount)))
				rtmpConnection.connect(broadcastURL!.absoluteString)
				retryCount += 1
				
			default: break
		}
	}
	
	@objc private func rtmpErrorHandler(_ notification: Notification) {
		print("Error: \(notification)")
	}
	
}
