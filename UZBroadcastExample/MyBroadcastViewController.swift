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

class MyBroadcastViewController: UZBroadcastViewController {
	let closeButton = NKButton()
	let switchButton = NKButton()
	let flashButton = NKButton()
	let beautyButton = NKButton()
	let focusButton = NKButton()
	let exposureButton = NKButton()
	let muteButton = NKButton()
	let frameLayout = VStackLayout()
	let statusLabel = UILabel()

	override func viewDidLoad() {
		super.viewDidLoad()
		
		statusLabel.alpha = 0.0
		statusLabel.font = .systemFont(ofSize: 12, weight: .medium)
		statusLabel.textColor = .black
		statusLabel.textAlignment = .center
		statusLabel.backgroundColor = .white
		statusLabel.layer.cornerRadius = 5
		statusLabel.layer.masksToBounds = true
		
		let iconSize = CGSize(width: 32, height: 32)
		
		closeButton.images[.normal] = UIImage(icon: .googleMaterialDesign(.close), size: iconSize, textColor: .white, backgroundColor: .clear)
		closeButton.addTarget(self, action: #selector(askForClose), for: .touchUpInside)
		closeButton.showsTouchWhenHighlighted = true
		
		switchButton.images[.normal] = UIImage(icon: .googleMaterialDesign(.cameraFront), size: iconSize, textColor: .white, backgroundColor: .clear)
		switchButton.images[.selected] = UIImage(icon: .googleMaterialDesign(.cameraRear), size: iconSize, textColor: .black, backgroundColor: .clear)
		switchButton.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
		
		flashButton.images[.normal] = UIImage(icon: .googleMaterialDesign(.flashOff), size: iconSize, textColor: .white, backgroundColor: .clear)
		flashButton.images[.selected] = UIImage(icon: .googleMaterialDesign(.flashOn), size: iconSize, textColor: .black, backgroundColor: .clear)
		flashButton.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
		
		beautyButton.images[.normal] = UIImage(icon: .googleMaterialDesign(.photoFilter), size: iconSize, textColor: .white, backgroundColor: .clear)
		beautyButton.images[.selected] = UIImage(icon: .googleMaterialDesign(.photoFilter), size: iconSize, textColor: .black, backgroundColor: .clear)
		beautyButton.addTarget(self, action: #selector(toggleBeauty), for: .touchUpInside)
		
		muteButton.images[.normal] = UIImage(icon: .googleMaterialDesign(.volumeMute), size: iconSize, textColor: .white, backgroundColor: .clear)
		muteButton.images[.selected] = UIImage(icon: .googleMaterialDesign(.volumeMute), size: iconSize, textColor: .black, backgroundColor: .clear)
		muteButton.addTarget(self, action: #selector(toggleMute), for: .touchUpInside)
		
		focusButton.images[.normal] = UIImage(icon: .googleMaterialDesign(.filterCenterFocus), size: iconSize, textColor: .white, backgroundColor: .clear)
		focusButton.images[.selected] = UIImage(icon: .googleMaterialDesign(.filterCenterFocus), size: iconSize, textColor: .black, backgroundColor: .clear)
		focusButton.addTarget(self, action: #selector(toggleAutoFocus), for: .touchUpInside)
		
		exposureButton.images[.normal] = UIImage(icon: .googleMaterialDesign(.exposure), size: iconSize, textColor: .white, backgroundColor: .clear)
		exposureButton.images[.selected] = UIImage(icon: .googleMaterialDesign(.exposure), size: iconSize, textColor: .black, backgroundColor: .clear)
		exposureButton.addTarget(self, action: #selector(toggleAutoExposure), for: .touchUpInside)
		
		let buttons = [flashButton, beautyButton, switchButton, focusButton, exposureButton, muteButton]
		buttons.forEach {
			$0.titleColors[.normal] = .white
			$0.titleColors[.selected] = .black
			$0.borderColors[.normal] = .white
			$0.borderColors[.selected] = .black
			$0.backgroundColors[.normal] = .clear
			$0.backgroundColors[.selected] = .white
			$0.borderSizes[.normal] = 1
			$0.extendSize = CGSize(width: 4, height: 4)
			$0.titleFonts[.normal] = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
			$0.isRoundedButton = true
			$0.showsTouchWhenHighlighted = true
			view.addSubview($0)
		}
		
		view.addSubview(closeButton)
		view.addSubview(statusLabel)
		view.addSubview(frameLayout)
		
		(frameLayout + 0).flexible()
		frameLayout + HStackLayout {
			$0 + buttons
			$0.distribution = .center
			$0.spacing = 10
		}
		
		frameLayout.padding(top: 30, left: 16, bottom: 48, right: 16)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		updateButtons()
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		let viewSize = view.bounds.size
		let buttonSize = CGSize(width: 33, height: 33)
		closeButton.frame = CGRect(x: viewSize.width - buttonSize.width - 15, y: 30, width: buttonSize.width, height: buttonSize.height)
		frameLayout.frame = view.bounds
		
		var labelSize = statusLabel.sizeThatFits(viewSize)
		labelSize.width += 8
		labelSize.height += 4
		statusLabel.frame = CGRect(x: (viewSize.width - labelSize.width)/2, y: 30, width: labelSize.width, height: labelSize.height)
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
		beautyButton.isSelected = session.beautyFace
		flashButton.isSelected = session.torch
		focusButton.isSelected = session.continuousAutoFocus
		exposureButton.isSelected = session.continuousAutoExposure
		muteButton.isSelected = session.muted
	}
	
	@objc func switchCamera() {
		cameraPosition = cameraPosition == .front ? .back : .front
		updateButtons()
	}
	
	@objc func toggleBeauty() {
		session.beautyFace = !session.beautyFace
		session.beautyLevel = 1.0
		updateButtons()
		showStatus(session.beautyFace ? "Beauty On" : "Beauty Off")
	}
	
	@objc func toggleFlash() {
		session.torch = !session.torch
		updateButtons()
		
		if cameraPosition == .front {
			showStatus("Flash is not available with front camera")
		}
		else {
			showStatus(session.beautyFace ? "Flash On" : "Flash Off")
		}
	}
	
	@objc func toggleAutoFocus() {
		session.continuousAutoFocus = !session.continuousAutoFocus
		updateButtons()
		showStatus(session.continuousAutoFocus ? "Auto Focus On" : "Auto Focus Off")
	}
	
	@objc func toggleAutoExposure() {
		session.continuousAutoExposure = !session.continuousAutoExposure
		updateButtons()
		showStatus(session.continuousAutoExposure ? "Auto Exposure On" : "Auto Exposure Off")
	}
	
	@objc func toggleMute() {
		session.muted = !session.muted
		updateButtons()
		showStatus(session.muted ? "Muted" : "Unmuted")
	}
	
}
