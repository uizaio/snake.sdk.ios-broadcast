//
//  UZLiveView.swift
//  UizaSDK
//
//  Created by Nam Kennic on 8/28/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import HaishinKit
import ReplayKit

/**
This class helps you to initialize a livestream session
*/

@available(iOSApplicationExtension, unavailable)
open class UZBroadcastViewController: UIViewController, RTMPStreamDelegate {
	/// Current broadcastURL
	public private(set) var broadcastURL: URL?
	/// Current streamKey
	public private(set) var streamKey: String?
	
	/// Set active camera
	public var cameraPosition: UZCameraPosition = .front {
		didSet {
			guard cameraPosition != oldValue else { return }
			DispatchQueue.main.async {
				self.rtmpStream.captureSettings[.isVideoMirrored] = self.cameraPosition == .front
				self.rtmpStream.attachCamera(DeviceUtil.device(withPosition: self.cameraPosition.value())) { error in
					print(error)
				}
			}
		}
	}
	/// Toggle torch mode
	public var torch: Bool {
		get { rtmpStream.torch }
		set { rtmpStream.torch = newValue }
	}
	/// Toggle mirror mode, only apply to front camera
	public var isMirror: Bool {
		get { (rtmpStream.captureSettings[.isVideoMirrored] as? Bool) ?? false }
		set { rtmpStream.captureSettings[.isVideoMirrored] = newValue && cameraPosition == .front }
	}
	/// Toggle auto focus, only apply to back camera
	public var isAutoFocus: Bool {
		get { (rtmpStream.captureSettings[.continuousAutofocus] as? Bool) ?? false }
		set { rtmpStream.captureSettings[.continuousAutofocus] = newValue }
	}
	/// Toggle auto exposure, only apply to back camera
	public var isAutoExposure: Bool {
		get { (rtmpStream.captureSettings[.continuousExposure] as? Bool) ?? false }
		set { rtmpStream.captureSettings[.continuousExposure] = newValue }
	}
	/// Toggle audio mute
	public var isMuted: Bool {
		get { (rtmpStream.audioSettings[.muted] as? Bool) ?? false }
		set { rtmpStream.audioSettings[.muted] = newValue }
	}
	/// Pause or unpause streaming
	public var isPaused: Bool {
		get { rtmpStream.paused }
		set { rtmpStream.paused = newValue }
	}
	/// Video Bitrate
	public var videoBitrate: UInt32? {
		get { rtmpStream.videoSettings[.bitrate] as? UInt32 }
		set {
			rtmpStream.videoSettings[.bitrate] = newValue
			if let value = newValue, minVideoBitrate == nil { minVideoBitrate = value / 8 }
		}
	}
	/// Minimum Video Bitrate (is used when `adaptiveBitrate` is `true`)
	public var minVideoBitrate: UInt32?
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
	/// Video gravity mode
	public var videoGravity: AVLayerVideoGravity {
		get { lfView.videoGravity }
		set { lfView.videoGravity = newValue }
	}
	/// Video Effect applied to the stream
	public var videoEffect: VideoEffect? {
		didSet {
			if let oldEffect = oldValue {
				_ = rtmpStream.unregisterVideoEffect(oldEffect)
			}
			
			guard let value = videoEffect else { return }
			_ = rtmpStream.registerVideoEffect(value)
		}
	}
	
	/// `true` if broadcasting
	public fileprivate(set)var isBroadcasting = false
	/// Current broadcast configuration
	public fileprivate(set) var config: UZBroadcastConfig! {
		didSet {
			videoBitrate = config.videoBitrate.value()
			videoFPS = config.videoFPS.rawValue
			audioBitrate = config.audioBitrate.rawValue
			audioSampleRate = config.audioSampleRate.rawValue
			cameraPosition = config.cameraPosition
			
			if let orientation = DeviceUtil.videoOrientation(by: UIApplication.shared.statusBarOrientation) {
				rtmpStream.orientation = orientation
			}
			rtmpStream.captureSettings = [
				.sessionPreset: config.videoResolution.sessionPreset,
				.continuousAutofocus: true,
				.continuousExposure: true
				// .preferredVideoStabilizationMode: AVCaptureVideoStabilizationMode.auto
			]
			rtmpStream.videoSettings = [
				.width: config.videoResolution.videoSize.width,
				.height: config.videoResolution.videoSize.height,
				.scalingMode: ScalingMode.normal
			]
		}
	}
	
	private var rtmpConnection = RTMPConnection()
	internal lazy var rtmpStream = RTMPStream(connection: rtmpConnection)
	private let lfView = GLHKView(frame: .zero)
	
	
	// MARK: -
	
	@discardableResult
	open func requestCameraAccess() -> Bool {
		let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
		switch status {
			case AVAuthorizationStatus.notDetermined:
				AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted) in
					if granted {
						if let url = self.broadcastURL, let key = self.streamKey {
							self.startBroadcast(broadcastURL: url, streamKey: key)
						}
					}
				})
				
			case AVAuthorizationStatus.authorized: return true
			case AVAuthorizationStatus.denied: break
			case AVAuthorizationStatus.restricted: break
			@unknown default:break
		}
		
		return false
	}
	
	@discardableResult
	open func requestMicrophoneAccess() -> Bool {
		let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
		switch status {
			case AVAuthorizationStatus.notDetermined: AVCaptureDevice.requestAccess(for: AVMediaType.audio, completionHandler: { granted in
				if granted {
					if let url = self.broadcastURL, let key = self.streamKey {
						self.startBroadcast(broadcastURL: url, streamKey: key)
					}
				}
			})
			
			case AVAuthorizationStatus.authorized: return true
			case AVAuthorizationStatus.denied: break
			case AVAuthorizationStatus.restricted: break
			@unknown default: break
		}
		
		return false
	}
	
	/**
	Always call this function first to prepare broadcasting with configuration
	- parameter config: Broadcast configuration
	*/
	@discardableResult
	public func prepareForBroadcast(config: UZBroadcastConfig) -> RTMPStream {
		self.config = config
		return rtmpStream
	}
	
	/**
	Start broadcasting
	- parameter broadcastURL: `URL` of broadcast
	- parameter streamKey: Stream Key
	*/
	public func startBroadcast(broadcastURL: URL, streamKey: String) {
		guard isBroadcasting == false else { return }
		
		self.broadcastURL = broadcastURL
		self.streamKey = streamKey
		
		if requestCameraAccess() && requestMicrophoneAccess() {
			startStream()
		}
	}
	
	private func startStream() {
		rtmpStream.delegate = self
		rtmpStream.attachAudio(AVCaptureDevice.default(for: .audio)) { error in
			print(error)
		}
		rtmpStream.attachCamera(DeviceUtil.device(withPosition: cameraPosition.value())) { error in
			print(error)
		}
//		rtmpStream.addObserver(self, forKeyPath: "currentFPS", options: .new, context: nil)
		
		lfView.videoGravity = .resizeAspectFill
		lfView.attachStream(rtmpStream)
		
		openConnection()
	}
	
	private func openConnection() {
		guard broadcastURL != nil, streamKey != nil else { return }
		isBroadcasting = true
		UIApplication.shared.isIdleTimerDisabled = true
		
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
	Stop broadcasting
	*/
	public func stopBroadcast() {
		closeConnection()
		isBroadcasting = false
		UIApplication.shared.isIdleTimerDisabled = false
	}
	
	
	// MARK: -
	
	open override func viewDidLoad() {
		super.viewDidLoad()
		
		view.backgroundColor = .black
		view.addSubview(lfView)
		
		NotificationCenter.default.addObserver(self, selector: #selector(onOrientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
	}
	
	open override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
//		rtmpStream.removeObserver(self, forKeyPath: "currentFPS")
		rtmpStream.close()
		rtmpStream.dispose()
		
		UIApplication.shared.isIdleTimerDisabled = false
	}
	
	open override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if requestCameraAccess() == false { print("Camera permission is not granted. Please turn it on in Settings. Implement your own permission check to handle this case.") }
		if requestMicrophoneAccess() == false { print("Microphone permission is not granted. Please turn it on in Settings. Implement your own permission check to handle this case.") }
	}
	
	open override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		lfView.frame = view.bounds
	}

	
	// MARK: - StatusBar & Rotation Handler
	
	open override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
	
	open override var shouldAutorotate: Bool {
		return config.autoRotate ?? (UIDevice.current.userInterfaceIdiom == .pad)
	}
	
	open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return config.autoRotate == true ? .all : (UIDevice.current.userInterfaceIdiom == .phone ? .portrait : .all)
	}
	
	open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
		return UIDevice.current.userInterfaceIdiom == .pad ? UIApplication.shared.interfaceOrientation ?? .portrait : .portrait
	}
	
	// MARK: - Events
	
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
	
	@objc private func onOrientationChanged(_ notification: Notification) {
		guard let orientation = DeviceUtil.videoOrientation(by: UIApplication.shared.statusBarOrientation) else { return }
		rtmpStream.orientation = orientation
		
		if orientation == .landscapeLeft || orientation == .landscapeRight {
			rtmpStream.videoSettings = [
				.width: config.videoResolution.videoSize.height,
				.height: config.videoResolution.videoSize.width,
			]
		}
		else {
			rtmpStream.videoSettings = [
				.width: config.videoResolution.videoSize.width,
				.height: config.videoResolution.videoSize.height,
			]
		}
	}
	
	@objc private func didEnterBackground(_ notification: Notification) {
		 rtmpStream.receiveVideo = false
	}
	
	@objc private func didBecomeActive(_ notification: Notification) {
		 rtmpStream.receiveVideo = true
	}
	
//	open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
//		if Thread.isMainThread {
//			print("currentFPS: \(rtmpStream.currentFPS)")
//		}
//	}
	
	func tapScreen(_ gesture: UIGestureRecognizer) {
		guard let gestureView = gesture.view, gesture.state == .ended else { return }
		let touchPoint = gesture.location(in: gestureView)
		let pointOfInterest = CGPoint(x: touchPoint.x / gestureView.bounds.size.width, y: touchPoint.y / gestureView.bounds.size.height)
		print("pointOfInterest: \(pointOfInterest)")
		rtmpStream.setPointOfInterest(pointOfInterest, exposure: pointOfInterest)
	}
	
	// MARK: - RTMPStreamDelegate
	
	public func rtmpStream(_ stream: RTMPStream, didPublishInsufficientBW connection: RTMPConnection) {
		guard config.adaptiveBitrate, let currentBitrate = rtmpStream.videoSettings[.bitrate] as? UInt32 else { return }
		let value = max(minVideoBitrate ?? currentBitrate, currentBitrate / 2)
		guard value != currentBitrate else { return }
		
		stream.videoSettings[.bitrate] = value
		print("bitRate decreased: \(value)kps")
	}
	
	public func rtmpStream(_ stream: RTMPStream, didPublishSufficientBW connection: RTMPConnection) {
		guard config.adaptiveBitrate, let currentBitrate = rtmpStream.videoSettings[.bitrate] as? UInt32 else { return }
		let value = min(videoBitrate ?? currentBitrate, currentBitrate * 2)
		guard value != currentBitrate else { return }
		
		stream.videoSettings[.bitrate] = value
		print("bitRate increased: \(value)kps")
	}
	
	public func rtmpStreamDidClear(_ stream: RTMPStream) {
		
	}
	
	// MARK: -
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
}

extension UIApplication {
	
	@available(iOSApplicationExtension, unavailable)
	var interfaceOrientation: UIInterfaceOrientation? {
		if #available(iOS 13, *) {
			return UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation
		}
		else {
			return UIApplication.shared.statusBarOrientation
		}
	}
	
}
