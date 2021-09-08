import AVFoundation
import HaishinKit
import UIKit

final class PronamaEffect: VideoEffect {
    let filter: CIFilter? = CIFilter(name: "CISourceOverCompositing")

	var image: UIImage!
    var extent = CGRect.zero {
        didSet {
            if extent == oldValue || image == nil { return }
            UIGraphicsBeginImageContext(extent.size)
            image.draw(at: CGPoint(x: 50, y: 50))
            pronama = CIImage(image: UIGraphicsGetImageFromCurrentImageContext()!, options: nil)
            UIGraphicsEndImageContext()
        }
    }
    var pronama: CIImage?

	required convenience init(image: UIImage) {
		self.init()
		self.image = image
	}
	
	override init() {
        super.init()
    }

    override func execute(_ image: CIImage, info: CMSampleBuffer?) -> CIImage {
        guard let filter: CIFilter = filter else { return image }
        extent = image.extent
        filter.setValue(pronama!, forKey: kCIInputImageKey)
        filter.setValue(image, forKey: kCIInputBackgroundImageKey)
        return filter.outputImage!
    }
}

final class MonochromeEffect: VideoEffect {
    let filter: CIFilter? = CIFilter(name: "CIColorMonochrome")

    override func execute(_ image: CIImage, info: CMSampleBuffer?) -> CIImage {
        guard let filter: CIFilter = filter else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIColor(red: 0.75, green: 0.75, blue: 0.75), forKey: kCIInputColorKey)
        filter.setValue(1.0, forKey: kCIInputIntensityKey)
        return filter.outputImage!
    }
}

final class BeautyEffect: VideoEffect {
//	let filter = CIFilter(name: "CIGaussianBlur")
//	let blendFilter = CIFilter(name: "CISoftLightBlendMode")
	
	override func execute(_ image: CIImage, info: CMSampleBuffer?) -> CIImage {
//		guard let filter = filter, let blendFilter = blendFilter else { return image }
//		blendFilter.setDefaults()
		
		var output = image
		let filters = image.autoAdjustmentFilters(options: [CIImageAutoAdjustmentOption.redEye : false])
		filters.forEach {
			$0.setValue(output, forKey: kCIInputImageKey)
			output = $0.outputImage!
		}
		
//		filter.setValue(output, forKey: kCIInputImageKey)
//		filter.setValue(8.0, forKey: kCIInputRadiusKey)
//		blendFilter.setValue(filter.outputImage!, forKey: kCIInputImageKey)
//		blendFilter.setValue(output, forKey: kCIInputBackgroundImageKey)
		
		return output
	}
}
