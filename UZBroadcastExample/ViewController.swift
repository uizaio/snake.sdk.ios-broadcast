//
//  ViewController.swift
//  UZBroadcastExample
//
//  Created by Nam Kennic on 3/17/20.
//  Copyright © 2020 Uiza. All rights reserved.
//

import UIKit
import AVFoundation
import HaishinKit
//import UZBroadcast

struct TableItem {
	var title: String
	var value: String
	var options: [String]
}

struct TableSection {
	var title: String
	var items: [TableItem]
}

enum TableSectionType: String {
	case videoResolution = "Resolution"
	case videoBitrate = "Bitrate"
	case videoFPS = "FPS"
	case audioBitrate = "Bitrate "
	case audioSampleRate = "SampleRate"
	case adaptiveBitrate = "Adaptive Bitrate"
	case autoRotate = "Auto rotation"
	case autoRetry = "Enable Auto Reconnect"
	case maxRetry = "Maximum Retries"
	case retryDelay = "Retry Delay"
	case saveToLocal = "Save to local"
}

@available(iOS 13.0, *)
class ViewController: UIViewController {
	let tableView = UITableView(frame: .zero, style: .grouped)
	let startButton = UIButton(type: .system)
	let speedTestButton = UIButton(type: .system)
	let speedLabel = UILabel()
	let squareView = UIView()
	
	var sections: [TableSection] = [] {
		didSet {
			tableView.reloadData()
		}
	}
	
	var videoResolution: UZVideoResolution = ._720
	var videoBitrate: UZVideoBitrate = ._4000Kbps
	var videoFPS: UZVideoFPS = ._30fps
	var audioBitrate: UZAudioBitrate = ._128Kbps
	var audioSampleRate: UZAudioSampleRate = ._44_1khz
	var adaptiveBitrate = true
	var saveToLocal = false
	var autoRotate = true
	var autoRetry = true
	var maxRetry = 20
	var retryInterval: TimeInterval = 10
	
	var broadcaster: UZScreenBroadcast?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let session = AVAudioSession.sharedInstance()
		do {
			try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
			try session.setActive(true)
		} catch {
			print(error)
		}
		
		speedLabel.font = .systemFont(ofSize: 14, weight: .medium)
		speedLabel.textColor = .lightGray
		speedLabel.textAlignment = .center
		
		speedTestButton.setTitle("Speed Test", for: .normal)
		speedTestButton.addTarget(self, action: #selector(onSpeedTest), for: .touchUpInside)
		
		startButton.setTitle("Start Broadcast", for: .normal)
		startButton.setTitle("Stop Broadcast", for: .selected)
		startButton.addTarget(self, action: #selector(onStart), for: .touchUpInside)
		
		tableView.delegate = self
		tableView.dataSource = self
		
		squareView.isHidden = true
		squareView.backgroundColor = .purple
		
		view.addSubview(tableView)
		view.addSubview(startButton)
		view.addSubview(speedTestButton)
		view.addSubview(squareView)
		view.addSubview(speedLabel)
		
		updateValues()
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		let viewSize = view.bounds.size
		let buttonSize = CGSize(width: 120, height: 50)
		startButton.frame = CGRect(x: 10, y: viewSize.height - buttonSize.height - 20, width: viewSize.width - 20, height: buttonSize.height)
		speedTestButton.frame = CGRect(x: 10, y: startButton.frame.minY - buttonSize.height - 10, width: viewSize.width - 20, height: buttonSize.height)
		speedLabel.frame = CGRect(x: 10, y: speedTestButton.frame.minY - 20, width: viewSize.width - 20, height: 40)
		tableView.frame = view.bounds.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: buttonSize.height + 100, right: 0))
		
		let squareSize = CGSize(width: 100, height: 100)
		squareView.frame = CGRect(x: (viewSize.width - squareSize.width)/2, y: viewSize.height - squareSize.height - buttonSize.height - 50, width: squareSize.width, height: squareSize.height)
	}
	
	func startRotating() {
		squareView.isHidden = false
		squareView.layer.removeAllAnimations()
		let rotate = CABasicAnimation(keyPath: "transform.rotation.z")
		rotate.duration = 3.0
		rotate.toValue = NSNumber(value: Double.pi * 2)
		rotate.repeatCount = .infinity
		rotate.isRemovedOnCompletion = false
		squareView.layer.add(rotate, forKey: "")
	}
	
	func stopRotating() {
		squareView.layer.removeAllAnimations()
	}
	
	@objc func onSpeedTest() {
		speedTestButton.isEnabled = false
		
		let url = URL(string: "https://beta.speedtest.net/api/js/servers?engine=js")
		UZSpeedTest.shared.testUploadSpeed(url!, fileSize: 50_000_000, timeout: 10) { [weak self] current, average in
			guard let self = self else { return }
			self.speedLabel.text = "Current: \(current.pretty) - Average: \(average.pretty)"
			self.view.setNeedsLayout()
		} final: { [weak self] result in
			guard let self = self else { return }
			self.speedTestButton.isEnabled = true
			
			switch result {
				case .value(let speed):
					let resultString = "Upload Speed: \(speed.pretty)"
					print(resultString)
					self.speedLabel.text = resultString
					self.showAlert(message: resultString)
					break
				case .error(let error):
					print("Speed test error: \(error)")
					self.showAlert(message: "Error: \(error.localizedDescription)")
					break
			}
		}
	}
	
	@objc func onStart() {
		if startButton.isSelected {
			stopScreenBroadcasting()
			return
		}
		
		let alertController = UIAlertController(title: "Start broadcast", message: "Please enter your broadcast URL", preferredStyle: .alert)
		alertController.addTextField { (textField) in
			textField.text = UserDefaults.standard.string(forKey: "lastUrl")
			textField.placeholder = "URL"
			textField.keyboardType = .URL
			textField.returnKeyType = .done
		}
		alertController.addTextField { (textField) in
			textField.text = UserDefaults.standard.string(forKey: "laststreamKey")
			textField.placeholder = "streamKey"
			textField.keyboardType = .default
			textField.returnKeyType = .next
		}
		alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
			alertController.dismiss(animated: true, completion: nil)
		}))
		alertController.addAction(UIAlertAction(title: "Start Livestream", style: .default, handler: { [weak self] (action) in
			guard let textFields = alertController.textFields else { return }
			guard let url = URL(string: textFields.first?.text ?? ""), let streamKey = textFields.last?.text else { return }
			self?.startBroadcasting(url: url, streamKey: streamKey)
			alertController.dismiss(animated: true, completion: nil)
		}))
		
		alertController.addAction(UIAlertAction(title: "Screen Broadcast", style: .default, handler: { [weak self] (action) in
			guard let textFields = alertController.textFields else { return }
			guard let url = URL(string: textFields.first?.text ?? ""), let streamKey = textFields.last?.text else { return }
			self?.startScreenBroadcasting(url: url, streamKey: streamKey)
			alertController.dismiss(animated: true, completion: nil)
		}))
		
		present(alertController, animated: true, completion: nil)
	}
	
	func updateValues() {
		sections = [TableSection(title: "Video", items: [TableItem(title: TableSectionType.videoResolution.rawValue, value: videoResolution.toString(), options: UZVideoResolution.allCases.compactMap({ return $0.toString() })),
														 TableItem(title: TableSectionType.videoBitrate.rawValue, value: videoBitrate.toString(), options: UZVideoBitrate.allCases.compactMap({ return $0.toString() })),
														 TableItem(title: TableSectionType.videoFPS.rawValue, value: videoFPS.toString(), options: UZVideoFPS.allCases.compactMap({ return $0.toString() }))]),
					
					TableSection(title: "Audio", items: [TableItem(title: TableSectionType.audioBitrate.rawValue, value: audioBitrate.toString(), options: UZAudioBitrate.allCases.compactMap({ return $0.toString() })),
														 TableItem(title: TableSectionType.audioSampleRate.rawValue, value: audioSampleRate.toString(), options: UZAudioSampleRate.allCases.compactMap({ return $0.toString() }))]),
		
					TableSection(title: "Option", items: [TableItem(title: TableSectionType.adaptiveBitrate.rawValue, value: adaptiveBitrate.toString(), options: [true, false].compactMap({ return $0.toString() })),
														  TableItem(title: TableSectionType.autoRotate.rawValue, value: autoRotate.toString(), options: [true, false].compactMap({ return $0.toString() })),
														  TableItem(title: TableSectionType.saveToLocal.rawValue, value: saveToLocal.toString(), options: [true, false].compactMap({ return $0.toString() }))]),
		
					TableSection(title: "Auto Reconnect", items: [TableItem(title: TableSectionType.autoRetry.rawValue, value: autoRetry.toString(), options: [true, false].compactMap({ return $0.toString() })),
																  TableItem(title: TableSectionType.maxRetry.rawValue, value: "\(maxRetry)", options: Array(1...100).map({ return "\($0)" })),
																  TableItem(title: TableSectionType.retryDelay.rawValue, value: "\(retryInterval)s", options: Array(1...60).map({ return "\($0)s" }))])]
	}
	
	func startBroadcasting(url: URL, streamKey: String) {
		UserDefaults.standard.set(url.absoluteString, forKey: "lastUrl")
		UserDefaults.standard.set(streamKey, forKey: "laststreamKey")
		
		let config = UZBroadcastConfig(cameraPosition: .front,
									   videoResolution: videoResolution,
									   videoBitrate: videoBitrate,
									   videoFPS: videoFPS,
									   audioBitrate: audioBitrate,
									   audioSampleRate: audioSampleRate,
									   adaptiveBitrate: adaptiveBitrate,
									   autoRotate: autoRotate,
									   saveToLocal: saveToLocal)
		
		let broadcastViewController = MyBroadcastViewController()
		broadcastViewController.prepareForBroadcast(config: config)
		broadcastViewController.maxRetryCount = autoRetry ? maxRetry : 0
		broadcastViewController.retryGapInterval = retryInterval
		broadcastViewController.modalPresentationStyle = .fullScreen
		
		present(broadcastViewController, animated: false) {
			broadcastViewController.startBroadcast(broadcastURL: url, streamKey: streamKey)
		}
	}
	
	@available(iOS 13.0, *)
	func startScreenBroadcasting(url: URL, streamKey: String) {
		guard broadcaster == nil else {
			stopScreenBroadcasting()
			return
		}
		
		startRotating()
		
		UserDefaults.standard.set(url.absoluteString, forKey: "lastUrl")
		UserDefaults.standard.set(streamKey, forKey: "laststreamKey")
		
		startButton.isSelected = true
		let config = UZBroadcastConfig(cameraPosition: .front,
									   videoResolution: videoResolution,
									   videoBitrate: videoBitrate,
									   videoFPS: videoFPS,
									   audioBitrate: audioBitrate,
									   audioSampleRate: audioSampleRate,
									   adaptiveBitrate: adaptiveBitrate,
									   autoRotate: autoRotate,
									   saveToLocal: saveToLocal)
		
		broadcaster = UZScreenBroadcast()
		broadcaster?.delegate = self
		broadcaster!.prepareForBroadcast(config: config)
		broadcaster!.isCameraEnabled = false
		broadcaster!.isMicrophoneEnabled = false
		broadcaster!.startBroadcast(broadcastURL: url, streamKey: streamKey) { error in
			print("Error: \(String(describing: error))")
		}
	}
	
	func stopScreenBroadcasting() {
		speedLabel.text = ""
		startButton.isSelected = false
		stopRotating()
		broadcaster?.stopBroadcast(handler: nil)
		broadcaster = nil
	}
	
	func switchValue(index: Int, for option: TableItem) {
		print("Switch \(option) index:\(index)")
		
		if option.title == TableSectionType.videoResolution.rawValue {
			videoResolution = UZVideoResolution.allCases[index]
		}
		else if option.title == TableSectionType.videoBitrate.rawValue {
			videoBitrate = UZVideoBitrate.allCases[index]
		}
		else if option.title == TableSectionType.videoFPS.rawValue {
			videoFPS = UZVideoFPS.allCases[index]
		}
		else if option.title == TableSectionType.audioBitrate.rawValue {
			audioBitrate = UZAudioBitrate.allCases[index]
		}
		else if option.title == TableSectionType.audioSampleRate.rawValue {
			audioSampleRate = UZAudioSampleRate.allCases[index]
		}
		else if option.title == TableSectionType.adaptiveBitrate.rawValue {
			adaptiveBitrate = index == 0
		}
		else if option.title == TableSectionType.autoRotate.rawValue {
			autoRotate = index == 0
		}
		else if option.title == TableSectionType.saveToLocal.rawValue {
			saveToLocal = index == 0
		}
		else if option.title == TableSectionType.autoRetry.rawValue {
			autoRetry = index == 0
		}
		else if option.title == TableSectionType.retryDelay.rawValue {
			retryInterval = Double(option.options[index].replacingOccurrences(of: "s", with: "")) ?? 1
		}
		else if option.title == TableSectionType.maxRetry.rawValue {
			maxRetry = Int(option.options[index]) ?? 0
		}
		
		updateValues()
	}
	
	func showOptions(item: TableItem) {
		let alertController = UIAlertController(title: item.title, message: nil, preferredStyle: .actionSheet)
		item.options.forEach { (title) in
			alertController.addAction(UIAlertAction(title: title, style: .default, handler: { [weak self] (action) in
				if let index = item.options.firstIndex(of: action.title ?? "") {
					self?.switchValue(index: index, for: item)
				}
			}))
		}
		alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
			alertController.dismiss(animated: true, completion: nil)
		}))
		present(alertController, animated: true, completion: nil)
	}
	
	func showAlert(message: String) {
		let alertControl = UIAlertController(title: nil, message: message, preferredStyle: .alert)
		alertControl.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
		UIViewController.topPresented()?.present(alertControl, animated: true, completion: nil)
	}
}

@available(iOS 13.0, *)
extension ViewController: UITableViewDelegate, UITableViewDataSource {
	
	func numberOfSections(in tableView: UITableView) -> Int { sections.count }
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { sections[section].items.count }
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		return tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		let item = sections[indexPath.section].items[indexPath.row]
		cell.textLabel?.font = .systemFont(ofSize: 14, weight: .bold)
		cell.detailTextLabel?.font = .systemFont(ofSize: 14, weight: .regular)
		cell.textLabel?.text = item.title
		cell.detailTextLabel?.text = item.value
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 55 }
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { sections[section].title }
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		showOptions(item: sections[indexPath.section].items[indexPath.row])
	}
	
}

@available(iOS 13.0, *)
extension ViewController: RTMPStreamDelegate {
	
	func rtmpStream(_ stream: RTMPStream, didPublishInsufficientBW connection: RTMPConnection) {
	}
	
	func rtmpStream(_ stream: RTMPStream, didPublishSufficientBW connection: RTMPConnection) {
	}
	
	func rtmpStream(_ stream: RTMPStream, didStatics connection: RTMPConnection) {
		speedLabel.text = "Current Speed: \(Speed(bytes: Int64(connection.currentBytesOutPerSecond), seconds: 1).pretty)"
	}
	
	func rtmpStream(_ stream: RTMPStream, didOutput video: CMSampleBuffer) {
	}
	
	func rtmpStream(_ stream: RTMPStream, didOutput audio: AVAudioBuffer, presentationTimeStamp: CMTime) {
	}
	
	func rtmpStreamDidClear(_ stream: RTMPStream) {
	}
	
}

extension Bool {
	
	func toString() -> String { self ? "On" : "Off" }
	
}
