import GPUImage
import HaishinKit
import Foundation

open class GPUImageRawOutput: GPUImageRawDataOutput {
	public weak var delegate: NetStream?
	
	public internal(set) var status: OSStatus = noErr
	public internal(set) var width: Int = 0
	public internal(set) var height: Int = 0
	
	public init(imageSize: CGSize) {
		super.init(imageSize: imageSize, resultsInBGRAFormat: true)
		width = Int(imageSize.width)
		height = Int(imageSize.height)
	}
	
	open override func setImageSize(_ newImageSize: CGSize) {
		super.setImageSize(newImageSize)
		width = Int(newImageSize.width)
		height = Int(newImageSize.height)
	}
	
	open override func newFrameReady(at frameTime: CMTime, at textureIndex: Int) {
		super.newFrameReady(at: frameTime, at: textureIndex)
		
		var pixelBuffer:CVPixelBuffer?
		status = CVPixelBufferCreateWithBytes(
			kCFAllocatorDefault,
			width,
			height,
			kCVPixelFormatType_32BGRA,
			rawBytesForImage,
			width * 4,
			nil,
			nil,
			nil,
			&pixelBuffer
		)
		
		guard let _pixelBuffer:CVPixelBuffer = pixelBuffer else { return }
		
		var description:CMVideoFormatDescription?
		status = CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: _pixelBuffer, formatDescriptionOut: &description)
		
		guard let _description:CMVideoFormatDescription = description else { return }
		
		var sampleBuffer:CMSampleBuffer?
		var timing:CMSampleTimingInfo = CMSampleTimingInfo()
		timing.presentationTimeStamp = frameTime
		status = CMSampleBufferCreateForImageBuffer(
			allocator: kCFAllocatorDefault,
			imageBuffer: _pixelBuffer,
			dataReady: true,
			makeDataReadyCallback: nil,
			refcon: nil,
			formatDescription: _description,
			sampleTiming: &timing,
			sampleBufferOut: &sampleBuffer
		)
		
		if (sampleBuffer != nil) {
			delegate?.appendSampleBuffer(sampleBuffer!, withType: .video)
		}
	}
}

