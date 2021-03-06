//
//  MyBroadcastViewController.swift
//  UZBroadcastExample
//
//  Created by Nam Kennic on 3/19/20.
//  Copyright © 2020 Uiza. All rights reserved.
//

import UIKit
import NKButton
import FrameLayoutKit
import SwiftIcons
import HaishinKit

class MyBroadcastViewController: UZBroadcastViewController {
	let closeButton = NKButton()
	let switchButton = NKButton()
	let mirrorButton = NKButton()
	let flashButton = NKButton()
	let filterButton = NKButton()
	let focusButton = NKButton()
	let exposureButton = NKButton()
	let muteButton = NKButton()
	let frameLayout = ZStackLayout()
	let liveLabel = LiveBadgeView()
	let statusLabel = UILabel()
	let speedLabel = UILabel()
	
	let beautyEffect = BeautyEffect()
	let monochromeEffect = MonochromeEffect()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		statusLabel.alpha = 0.0
		statusLabel.font = .systemFont(ofSize: 12, weight: .medium)
		statusLabel.textColor = .black
		statusLabel.textAlignment = .center
		statusLabel.backgroundColor = .white
		statusLabel.layer.cornerRadius = 5
		statusLabel.layer.masksToBounds = true
		
		speedLabel.font = .systemFont(ofSize: 14, weight: .medium)
		speedLabel.textColor = .white
		
		let iconSize = CGSize(width: 24, height: 24)
		
		closeButton.images[.normal] = UIImage(icon: .googleMaterialDesign(.close), size: CGSize(width: 32, height: 32), textColor: .white, backgroundColor: .clear)
		closeButton.addTarget(self, action: #selector(askForClose), for: .touchUpInside)
		closeButton.showsTouchWhenHighlighted = true
		
		switchButton.title = "Switch Camera"
		switchButton.images[.normal] = UIImage(icon: .googleMaterialDesign(.cameraFront), size: iconSize, textColor: .white, backgroundColor: .clear)
		switchButton.images[.selected] = UIImage(icon: .googleMaterialDesign(.cameraRear), size: iconSize, textColor: .black, backgroundColor: .clear)
		switchButton.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
		
		mirrorButton.title = "Mirror"
		mirrorButton.images[.normal] = UIImage(icon: .googleMaterialDesign(.flip), size: iconSize, textColor: .white, backgroundColor: .clear)
		mirrorButton.images[.selected] = UIImage(icon: .googleMaterialDesign(.flip), size: iconSize, textColor: .black, backgroundColor: .clear)
		mirrorButton.addTarget(self, action: #selector(toggleMirror), for: .touchUpInside)
		
		flashButton.title = "Flash"
		flashButton.images[.normal] = UIImage(icon: .googleMaterialDesign(.flashOff), size: iconSize, textColor: .white, backgroundColor: .clear)
		flashButton.images[.selected] = UIImage(icon: .googleMaterialDesign(.flashOn), size: iconSize, textColor: .black, backgroundColor: .clear)
		flashButton.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
		
		filterButton.title = "Filter"
		filterButton.images[.normal] = UIImage(icon: .googleMaterialDesign(.photoFilter), size: iconSize, textColor: .white, backgroundColor: .clear)
		filterButton.images[.selected] = UIImage(icon: .googleMaterialDesign(.photoFilter), size: iconSize, textColor: .black, backgroundColor: .clear)
		filterButton.addTarget(self, action: #selector(toggleFilter), for: .touchUpInside)
		
		muteButton.title = "Mute"
		muteButton.images[.normal] = UIImage(icon: .googleMaterialDesign(.volumeMute), size: iconSize, textColor: .white, backgroundColor: .clear)
		muteButton.images[.selected] = UIImage(icon: .googleMaterialDesign(.volumeMute), size: iconSize, textColor: .black, backgroundColor: .clear)
		muteButton.addTarget(self, action: #selector(toggleMute), for: .touchUpInside)
		
		focusButton.title = "Auto Focus"
		focusButton.images[.normal] = UIImage(icon: .googleMaterialDesign(.filterCenterFocus), size: iconSize, textColor: .white, backgroundColor: .clear)
		focusButton.images[.selected] = UIImage(icon: .googleMaterialDesign(.filterCenterFocus), size: iconSize, textColor: .black, backgroundColor: .clear)
		focusButton.addTarget(self, action: #selector(toggleAutoFocus), for: .touchUpInside)
		
		exposureButton.title = "Auto Exposure"
		exposureButton.images[.normal] = UIImage(icon: .googleMaterialDesign(.exposure), size: iconSize, textColor: .white, backgroundColor: .clear)
		exposureButton.images[.selected] = UIImage(icon: .googleMaterialDesign(.exposure), size: iconSize, textColor: .black, backgroundColor: .clear)
		exposureButton.addTarget(self, action: #selector(toggleAutoExposure), for: .touchUpInside)
		
		let buttons = [flashButton, filterButton, switchButton, mirrorButton, focusButton, exposureButton, muteButton]
		buttons.forEach {
			$0.titleColors[.normal] = .white
			$0.titleColors[.selected] = .black
			$0.borderColors[.normal] = .white
			$0.borderColors[.selected] = .black
			$0.backgroundColors[.normal] = .clear
			$0.backgroundColors[.selected] = .white
			$0.borderSizes[.normal] = 1
			$0.extendSize = CGSize(width: 8, height: 4)
			$0.titleFonts[.normal] = .systemFont(ofSize: 14, weight: .medium)
			$0.isRoundedButton = true
			$0.showsTouchWhenHighlighted = true
			view.addSubview($0)
		}
		
		view.addSubview(closeButton)
		view.addSubview(statusLabel)
		view.addSubview(liveLabel)
		view.addSubview(speedLabel)
		view.addSubview(frameLayout)
		
		frameLayout + VStackLayout {
			($0 + liveLabel).align(vertical: .center, horizontal: .center)
			($0 + 0).flexible()
			($0 + statusLabel)
				.align(vertical: .bottom, horizontal: .center)
				.extends(size: CGSize(width: 8, height: 4))
		}
		frameLayout + VStackLayout {
			($0 + 0).flexible()
			$0 + VStackLayout {
				($0 + buttons).forEach { $0.alignment = (.center, .right) }
				$0.distribution = .center
				$0.spacing = 10
			}
		}
		
		frameLayout.spacing(16).padding(top: view.extendSafeEdgeInsets.top + 16, left: 16, bottom: view.extendSafeEdgeInsets.bottom + 24, right: 16)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		updateButtons()
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		frameLayout.frame = view.bounds
		
		let viewSize = view.bounds.size
		let buttonSize = CGSize(width: 33, height: 33)
		closeButton.frame = CGRect(x: viewSize.width - buttonSize.width - 15, y: view.extendSafeEdgeInsets.top + 16, width: buttonSize.width, height: buttonSize.height)
		
		speedLabel.frame = CGRect(x: 10, y: viewSize.height - view.extendSafeEdgeInsets.bottom - 30, width: viewSize.width - 20, height: 30)
	}
	
	@discardableResult
	override func prepareForBroadcast(config: UZBroadcastConfig) -> RTMPStream {
		let stream = super.prepareForBroadcast(config: config)
		if config.saveToLocal {
			rtmpStream.mixer.recorder.delegate = RecorderDelegate.sharedInstance
		}
		
		return stream
	}
	
	override func startBroadcast(broadcastURL: URL, streamKey: String) {
		super.startBroadcast(broadcastURL: broadcastURL, streamKey: streamKey)
		liveLabel.startBlinking()
	}
	
	override func stopBroadcast() {
		super.stopBroadcast()
		liveLabel.stopBlinking()
	}
	
	override func requestCameraAccess() -> Bool {
		let granted = super.requestCameraAccess()
		if !granted {
			// show camera permission request dialog here
		}
		return granted
	}
	
	override func requestMicrophoneAccess() -> Bool {
		let granted = super.requestCameraAccess()
		if !granted {
			// show microphone permission request dialog here
		}
		return granted
	}
	
	func showStatus(_ string: String) {
		statusLabel.text = string
		view.setNeedsLayout()
		view.layoutIfNeeded()
		
		statusLabel.alpha = 1.0
		DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
			UIView.animate(withDuration: 0.2) {
				self.statusLabel.alpha = 0.0
			}
		}
	}
	
	@objc func askForClose() {
		let alertController = UIAlertController(title: "Stop Broadcasting?", message: nil, preferredStyle: .alert)
		alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
			alertController.dismiss(animated: true, completion: nil)
		}))
		alertController.addAction(UIAlertAction(title: "Stop", style: .destructive, handler: { [weak self] (action) in
			alertController.dismiss(animated: false, completion: nil)
			self?.stopBroadcast()
			self?.dismiss(animated: true, completion: nil)
		}))
		present(alertController, animated: true, completion: nil)
	}
	
	func updateButtons() {
		switchButton.isSelected = cameraPosition == .back
		filterButton.isSelected = videoEffect != nil
		mirrorButton.isSelected = isMirror
		flashButton.isSelected = torch
		focusButton.isSelected = isAutoFocus
		exposureButton.isSelected = isAutoExposure
		muteButton.isSelected = isMuted
	}
	
	@objc func switchCamera() {
		cameraPosition = cameraPosition == .front ? .back : .front
		updateButtons()
	}
	
	@objc func toggleFilter() {
		videoEffect = videoEffect == nil ? beautyEffect : videoEffect == beautyEffect ? monochromeEffect : nil
		updateButtons()
		showStatus(videoEffect == beautyEffect ? "Enchanced" : videoEffect == monochromeEffect ? "Monochrome" : "Filter Off")
	}
	
	@objc func toggleMirror() {
		isMirror = !isMirror
		updateButtons()
		showStatus(isMirror ? "Mirror On" : "Mirror Off")
	}
	
	@objc func toggleFlash() {
		torch = !torch
		updateButtons()

		if cameraPosition == .front {
			showStatus("Flash is not available with front camera")
		}
		else {
			showStatus(torch ? "Flash On" : "Flash Off")
		}
	}
	
	@objc func toggleAutoFocus() {
		isAutoFocus = !isAutoFocus
		updateButtons()
		showStatus(isAutoFocus ? "Auto Focus On" : "Auto Focus Off")
	}
	
	@objc func toggleAutoExposure() {
		isAutoExposure = !isAutoExposure
		updateButtons()
		showStatus(isAutoExposure ? "Auto Exposure On" : "Auto Exposure Off")
	}
	
	@objc func toggleMute() {
		isMuted = !isMuted
		updateButtons()
		showStatus(isMuted ? "Muted" : "Unmuted")
	}
	
	// MARK: -
	
	override func rtmpStream(_ stream: RTMPStream, didStatics connection: RTMPConnection) {
		speedLabel.text = "\(Speed(bytes: Int64(connection.currentBytesOutPerSecond), seconds: 1).pretty)"
	}
	
	// MARK: -
	
	override var shouldAutorotate: Bool { config.autoRotate }
	override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .all }
	
}


// MARK: - RecorderDelegate
import Photos
import AVFoundation
import VideoToolbox

final class RecorderDelegate: DefaultAVRecorderDelegate {
	static let sharedInstance = RecorderDelegate()
	
	override func didFinishWriting(_ recorder: AVRecorder) {
		guard let writer = recorder.writer else { return }
		
		DispatchQueue.main.async {
			PHPhotoLibrary.shared().performChanges {
				PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: writer.outputURL)
			} completionHandler: { success, error in
				DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
					if let error = error {
						self.showAlert(message: "Unable to save video: \(error.localizedDescription)")
					}
					else {
						self.showAlert(message: "Video successfully saved to Photos")
					}
				}
				
				do {
					try FileManager.default.removeItem(at: writer.outputURL)
				} catch {
					print(error)
				}
			}
		}
	}
	
	func showAlert(message: String) {
		let alertControl = UIAlertController(title: nil, message: message, preferredStyle: .alert)
		alertControl.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
		UIViewController.topPresented()?.present(alertControl, animated: true, completion: nil)
	}
	
}

class LiveBadgeView: FLView<HStackLayout> {
	let liveLabel = UILabel()
	let dotView = UIView()
	
	init() {
		super.init(frame: .zero)
		
		layer.cornerRadius = 5
		layer.masksToBounds = true
		backgroundColor = .systemRed
		
		liveLabel.text = "Live"
		liveLabel.textColor = .white
		liveLabel.textAlignment = .center
		liveLabel.font = .systemFont(ofSize: 14, weight: .medium)
		
		dotView.backgroundColor = .white
		dotView.layer.masksToBounds = true
		dotView.layer.cornerRadius = 4
		
		addSubview(liveLabel)
		addSubview(dotView)
		addSubview(frameLayout)
		
		(frameLayout + dotView).fixedContentSize(CGSize(width: 8, height: 8)).align(vertical: .center, horizontal: .center)
		(frameLayout + liveLabel).align(vertical: .center, horizontal: .center)
		frameLayout.padding(top: 4, left: 8, bottom: 4, right: 8).spacing(8)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func startBlinking() {
		DispatchQueue.main.async {
			self.dotView.blink()
		}
	}
	
	func stopBlinking() {
		DispatchQueue.main.async {
			self.dotView.layer.removeAllAnimations()
		}
	}
	
}
