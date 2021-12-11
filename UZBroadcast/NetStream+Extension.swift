import GPUImage
import HaishinKit
import Foundation

public extension NetStream {
	private static let tag = "com.haishinkit.GPUHaishinKit.GPUImageRawOutput"
	private static let size = CGSize(width: 355, height: 288)
	
	var rawDataOutput: GPUImageRawDataOutput {
		if let output = metadata[NetStream.tag] as? GPUImageRawOutput {
			return output
		}
		
		var size: CGSize?
		if let width = videoSettings[H264Encoder.Option.width] as? CGFloat,
		   let height = videoSettings[H264Encoder.Option.height] as? CGFloat {
			size = CGSize(width: width, height: height)
		}
		
		let output = GPUImageRawOutput(imageSize: size ?? NetStream.size)
		output.delegate = self
		metadata[NetStream.tag] = output
		return output
	}
	
#if os(iOS)
	func attachGPUImageVideoCamera(_ camera: GPUImageVideoCamera) {
		mixer.session = camera.captureSession
	}
#endif
}

