//
//  UZSpeedTest.swift
//  UZBroadcast
//
//  Created by Nam Kennic on 3/8/22.
//  Copyright © 2022 Uiza. All rights reserved.
//

import UIKit

public enum Result<T, E: Error> {
	case value(T)
	case error(E)
}

public class UZSpeedTest: NSObject {
	public static var shared = UZSpeedTest()
	
	private var responseDate: Date?
	private var latestDate: Date?
	private var current: ((Speed, Speed) -> ())!
	private var final: ((Result<Speed, Error>) -> ())!
	
	public func testUploadSpeed(_ url: URL, fileSize: Int, timeout: TimeInterval, current: @escaping (Speed, Speed) -> (), final: @escaping (Result<Speed, Error>) -> ()) {
		self.current = current
		self.final = final
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.timeoutInterval = timeout
		request.allHTTPHeaderFields = ["Content-Type": "application/octet-stream",
									   "Accept-Encoding": "gzip, deflate",
									   "Content-Length": "\(fileSize)",
									   "Connection": "keep-alive"]
		
		URLSession(configuration: sessionConfiguration(timeout: timeout), delegate: self, delegateQueue: .main)
			.uploadTask(with: request, from: Data(count: fileSize))
			.resume()
	}
	
}

extension UZSpeedTest: URLSessionDataDelegate {
	
	public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Swift.Void) {
		let result = calculate(bytes: dataTask.countOfBytesSent, seconds: Date().timeIntervalSince(self.responseDate!))
		DispatchQueue.main.async {
			self.final(.value(result))
		}
	}
	
}

extension UZSpeedTest: URLSessionTaskDelegate {
	
	public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
		guard let startDate = responseDate, let latesDate = latestDate else {
			responseDate = Date();
			latestDate = responseDate
			return
		}
		
		let currentTime = Date()
		let timeSpend = currentTime.timeIntervalSince(latesDate)
		
		let current = calculate(bytes: bytesSent, seconds: timeSpend)
		let average = calculate(bytes: totalBytesSent, seconds: -startDate.timeIntervalSinceNow)
		
		latestDate = currentTime
		
		DispatchQueue.main.async {
			self.current(current, average)
		}
	}
	
	public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
		DispatchQueue.main.async {
			self.final(.error(error!))
		}
	}
	
	public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		DispatchQueue.main.async {
			self.final(.error(error!))
		}
	}
}

extension UZSpeedTest {
	
	func calculate(bytes: Int64, seconds: TimeInterval) -> Speed {
		return Speed(bytes: bytes, seconds: seconds).pretty
	}
	
	func sessionConfiguration(timeout: TimeInterval) -> URLSessionConfiguration {
		let sessionConfig = URLSessionConfiguration.default
		sessionConfig.timeoutIntervalForRequest = timeout
		sessionConfig.timeoutIntervalForResource = timeout
		sessionConfig.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
		sessionConfig.urlCache = nil
		return sessionConfig
	}
}


// MARK: - Speed

public struct Speed: CustomStringConvertible {
	private static let bitsInBytes: Double = 8
	private static let upUnit: Double = 1000
	
	public enum Units: Int {
		case Kbps, Mbps, Gbps
		
		var description: String {
			switch self {
				case .Kbps: return "Kbps"
				case .Mbps: return "Mbps"
				case .Gbps: return "Gbps"
			}
		}
	}
	
	public let value: Double
	public let units: Units
	
	var pretty: Speed {
		return [Units.Kbps, .Mbps, .Gbps]
			.filter {
				$0.rawValue >= self.units.rawValue
			}.reduce(self) { (result, nextUnits) in
				guard result.value > Speed.upUnit else { return result }
				return Speed(value: result.value / Speed.upUnit, units: nextUnits)
			}
	}
	
	public var description: String {
		return String(format: "%.3f", value) + " " + units.description
	}
	
}

public extension Speed {
	
	init(bytes: Int64, seconds: TimeInterval) {
		let speedInB = Double(bytes) * Speed.bitsInBytes / seconds
		self.value = speedInB
		self.units = .Kbps
	}
	
}
