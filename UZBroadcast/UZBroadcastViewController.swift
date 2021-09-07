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
open class UZBroadcastViewController: UIViewController {
	public var broadcastURL: URL?
	public var streamKey: String?
	
	/// Set active camera
	public var cameraPosition: AVCaptureDevice.Position = .front {
		didSet {
			guard cameraPosition != oldValue else { return }
			rtmpStream.attachCamera(DeviceUtil.device(withPosition: cameraPosition)) { error in
				print(error)
			}
		}
	}
	
	public var torch: Bool {
		get { rtmpStream.torch }
		set { rtmpStream.torch = newValue }
	}
	
	public var isMirror: Bool {
		get { (rtmpStream.captureSettings[.isVideoMirrored] as? Bool) ?? false }
		set { rtmpStream.captureSettings[.isVideoMirrored] = newValue && cameraPosition == .front }
	}
	
	public var isAutoFocus: Bool {
		get { (rtmpStream.captureSettings[.continuousAutofocus] as? Bool) ?? false }
		set { rtmpStream.captureSettings[.continuousAutofocus] = newValue }
	}

	public var isAutoExposure: Bool {
		get { (rtmpStream.captureSettings[.continuousExposure] as? Bool) ?? false }
		set { rtmpStream.captureSettings[.continuousExposure] = newValue }
	}
	
	public var isMuted: Bool {
		get { (rtmpStream.audioSettings[.muted] as? Bool) ?? false }
		set { rtmpStream.audioSettings[.muted] = newValue }
	}
	
	public var isPaused: Bool {
		get { rtmpStream.paused }
		set { rtmpStream.paused = newValue }
	}
	
	public var videoBitrate: UInt32? {
		get { rtmpStream.videoSettings[.bitrate] as? UInt32 }
		set { rtmpStream.videoSettings[.bitrate] = newValue }
	}
	
	public var videoFPS: UInt? {
		get { rtmpStream.captureSettings[.fps] as? UInt }
		set { rtmpStream.captureSettings[.fps] = newValue }
	}
	
	public var audioBitrate: UInt32? {
		get { rtmpStream.audioSettings[.bitrate] as? UInt32 }
		set { rtmpStream.audioSettings[.bitrate] = newValue }
	}
	
	public var audioSampleRate: UInt32? {
		get { rtmpStream.audioSettings[.sampleRate] as? UInt32 }
		set { rtmpStream.audioSettings[.sampleRate] = newValue }
	}
	
	/// `true` if broadcasting
	public fileprivate(set)var isBroadcasting = false
	/// Current broadcast configuration
	public fileprivate(set) var config: UZBroadcastConfig! {
		didSet {
			cameraPosition = config.cameraPosition.asValue()
			videoBitrate = config.videoBitrate.rawValue
			videoFPS = config.videoFPS.rawValue
			audioBitrate = config.audioBitrate.rawValue
			audioSampleRate = config.audioSampleRate.rawValue
			
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
				.height: config.videoResolution.videoSize.height
			]
		}
	}
	
	private var rtmpConnection = RTMPConnection()
	internal lazy var rtmpStream = RTMPStream(connection: rtmpConnection)
	private let lfView = MTHKView(frame: .zero)
	
	
	// MARK: -
	
	/**
	Request accessing for video
	*/
	open func requestAccessForVideo() {
		let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
		switch status {
			case AVAuthorizationStatus.notDetermined:
				AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted) in
					if granted {
						self.startStream()
					}
				})
				
			case AVAuthorizationStatus.authorized: startStream()
			case AVAuthorizationStatus.denied: break
			case AVAuthorizationStatus.restricted: break
			@unknown default:break
		}
	}
	
	/**
	Request accessing for audio
	*/
	open func requestAccessForAudio() {
		let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
		switch status {
			case AVAuthorizationStatus.notDetermined: AVCaptureDevice.requestAccess(for: AVMediaType.audio, completionHandler: { (_) in })
			case AVAuthorizationStatus.authorized: break
			case AVAuthorizationStatus.denied: break
			case AVAuthorizationStatus.restricted: break
			@unknown default: break
		}
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
		isBroadcasting = true
		self.broadcastURL = broadcastURL
		self.streamKey = streamKey
		
//		let stream = LFLiveStreamInfo()
//		stream.url = broadcastURL.appendingPathComponent(streamKey).absoluteString
//		session.startLive(stream)
		
		UIApplication.shared.isIdleTimerDisabled = true
	}
	
	private func startStream() {
		rtmpStream.attachAudio(AVCaptureDevice.default(for: .audio)) { error in
			print(error)
		}
		rtmpStream.attachCamera(DeviceUtil.device(withPosition: cameraPosition)) { error in
			print(error)
		}
//		rtmpStream.addObserver(self, forKeyPath: "currentFPS", options: .new, context: nil)
		lfView.attachStream(rtmpStream)
	}
	
	private func openConnection() {
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
//		session.stopLive()
//		session.running = false
//		session.delegate = nil
		
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
		
		requestAccessForVideo()
		requestAccessForAudio()
	}
	
	open override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		lfView.frame = view.bounds
	}

	
	// MARK: -
	
	open override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}
	
	open override var shouldAutorotate: Bool {
		return config.autoRotate ?? (UIDevice.current.userInterfaceIdiom == .pad)
	}
	
	open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return config.autoRotate == true ? .all : (UIDevice.current.userInterfaceIdiom == .phone ? .portrait : .all)
	}
	
	open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
		return UIDevice.current.userInterfaceIdiom == .pad ? UIApplication.shared.interfaceOrientation ?? .portrait : .portrait
	}
	
	// MARK: -
	
	var retryCount = 0
	var maxRetryCount = 5
	
	@objc private func rtmpStatusHandler(_ notification: Notification) {
		let e = Event.from(notification)
		guard let data: ASObject = e.data as? ASObject, let code: String = data["code"] as? String else { return }
		
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
		
	}
	
	@objc private func onOrientationChanged(_ notification: Notification) {
		guard let orientation = DeviceUtil.videoOrientation(by: UIApplication.shared.statusBarOrientation) else { return }
		rtmpStream.orientation = orientation
	}
	
	@objc private func didEnterBackground(_ notification: Notification) {
		 rtmpStream.receiveVideo = false
	}
	
	@objc private func didBecomeActive(_ notification: Notification) {
		 rtmpStream.receiveVideo = true
	}
	
	func tapScreen(_ gesture: UIGestureRecognizer) {
		guard let gestureView = gesture.view, gesture.state == .ended else { return }
		let touchPoint = gesture.location(in: gestureView)
		let pointOfInterest = CGPoint(x: touchPoint.x / gestureView.bounds.size.width, y: touchPoint.y / gestureView.bounds.size.height)
		print("pointOfInterest: \(pointOfInterest)")
		rtmpStream.setPointOfInterest(pointOfInterest, exposure: pointOfInterest)
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
}

extension UIApplication {
	
	var interfaceOrientation: UIInterfaceOrientation? {
		if #available(iOS 13, *) {
			return UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation
		}
		else {
			return UIApplication.shared.statusBarOrientation
		}
	}
	
}
