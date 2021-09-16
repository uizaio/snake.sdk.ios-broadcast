//
//  UZBroadcastConfig.swift
//  UZBroadcast
//
//  Created by Nam Kennic on 3/26/20.
//  Copyright © 2020 Uiza. All rights reserved.
//

import UIKit
import AVFoundation
import HaishinKit

public enum UZVideoResolution: CaseIterable {
	case _360
	case _480
	case _720
	case _1080
	
	/// Convert to CGSize
	public var videoSize: CGSize {
		switch self {
			case ._360: return CGSize(width: 360, height: 640)
			case ._480: return CGSize(width: 480, height: 854)
			case ._720: return CGSize(width: 720, height: 1280)
			case ._1080: return CGSize(width: 1080, height: 1920)
		}
	}
	
	internal var sessionPreset: AVCaptureSession.Preset {
		switch self {
			case ._360: return .cif352x288
			case ._480: return .vga640x480
			case ._720: return .hd1280x720
			case ._1080: return .hd1920x1080
		}
	}
	//
	//	internal var videoQuality: LFLiveVideoQuality {
	//		switch self {
	//		case ._360: return .SD_360
	//		case ._480: return .SD_480
	//		case ._720: return .HD_720
	//		case ._1080: return .fullHD_1080
	//		}
	//	}
	
	/// Convert to readable string
	public func toString() -> String {
		var result = ""
		switch self {
			case ._360: result = "SD 360p"
			case ._480: result = "SD 480p"
			case ._720: result = "HD 720"
			case ._1080: result = "Full HD 1080"
		}
		
		return result + " (\(Int(videoSize.width))x\(Int(videoSize.height)))"
	}
	
}

public enum UZVideoBitrate: CaseIterable {
	case _500Kbps
	case _1000Kbps
	case _1500Kbps
	case _2000Kbps
	case _3000Kbps
	case _4000Kbps
	case _5000Kbps
	case _6000Kbps
	case custom(UInt32)
	
	public func value() -> UInt32 {
		switch self {
			case ._500Kbps: return 500_000
			case ._1000Kbps: return 1_000_000
			case ._1500Kbps: return 1_500_000
			case ._2000Kbps: return 2_000_000
			case ._3000Kbps: return 3_000_000
			case ._4000Kbps: return 4_000_000
			case ._5000Kbps: return 5_000_000
			case ._6000Kbps: return 6_000_000
			case .custom(let value): return value
		}
	}
	
	public static var allCases: [UZVideoBitrate] {
		[
			_500Kbps,
			_1000Kbps,
			_1500Kbps,
			_2000Kbps,
			_3000Kbps,
			_4000Kbps,
			_5000Kbps,
			_6000Kbps,
		]
	}
	
	/// Convert to readable string
	public func toString() -> String {
		return "\(self.value()/1000) Kbps"
	}
}

public enum UZVideoFPS: UInt, CaseIterable {
	case _30fps = 30
	case _60fps = 60
	
	/// Convert to readable string
	public func toString() -> String {
		return "\(self.rawValue) fps"
	}
}

public enum UZAudioBitrate: UInt32, CaseIterable {
	case _32Kbps = 32_000
	case _64Kbps = 64_000
	case _96Kbps = 96_000
	case _128Kbps = 128_000
	
	//	internal func toLFLiveAudioBitRate() -> LFLiveAudioBitRate {
	//		switch self {
	//		case ._64Kbps: return ._64Kbps
	//		case ._96Kbps: return ._96Kbps
	//		case ._128Kbps: return ._128Kbps
	//		}
	//	}
	
	/// Convert to readable string
	public func toString() -> String {
		return "\(self.rawValue/1000) Kbps"
	}
}

public enum UZAudioSampleRate: UInt32, CaseIterable {
	case _44_1khz = 44_100
	case _48_0khz = 48_000
	
	//	internal func toLFLiveAudioSampleRate() -> LFLiveAudioSampleRate {
	//		switch self {
	//		case ._44_1khz: return ._44100Hz
	//		case ._48_0khz: return ._48000Hz
	//		}
	//	}
	
	/// Convert to readable string
	public func toString() -> String {
		return "\(Double(self.rawValue)/1000) KHz"
	}
}

public enum UZCameraPosition {
	case front
	case back
	
	func value() -> AVCaptureDevice.Position {
		switch self {
			case .front: return .front
			case .back: return .back
		}
	}
}

public struct UZBroadcastConfig {
	public var cameraPosition: UZCameraPosition
	public var videoResolution: UZVideoResolution
	public var videoBitrate: UZVideoBitrate
	public var videoFPS: UZVideoFPS
	public var audioBitrate: UZAudioBitrate
	public var audioSampleRate: UZAudioSampleRate
	public var adaptiveBitrate: Bool
	public var autoRotate: Bool
	public var saveToLocal: Bool
	
	public init(cameraPosition: UZCameraPosition, videoResolution: UZVideoResolution, videoBitrate: UZVideoBitrate, videoFPS: UZVideoFPS, audioBitrate: UZAudioBitrate, audioSampleRate: UZAudioSampleRate, adaptiveBitrate: Bool = true, autoRotate: Bool = true, saveToLocal: Bool = false) {
		self.cameraPosition = cameraPosition
		self.videoResolution = videoResolution
		self.videoBitrate = videoBitrate
		self.videoFPS = videoFPS
		self.audioBitrate = audioBitrate
		self.audioSampleRate = audioSampleRate
		self.adaptiveBitrate = adaptiveBitrate
		self.autoRotate = autoRotate
		self.saveToLocal = saveToLocal
	}
}
