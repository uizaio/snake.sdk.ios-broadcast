# UZBroadcast
![Swift](https://img.shields.io/badge/%20in-swift%205.0-orange.svg)

UZBroadcast is a framework helps you to broadcast livestream

## Compatibility
UZBroadcast requires Swift 4.2+ and iOS 9+

## Installation

### CocoaPods
To integrate UZBroadcast into your Xcode project using [CocoaPods](http://cocoapods.org), specify it in your `Podfile`:

```ruby
use_modular_headers!
pod 'UZBroadcast'
```

Since this framework includes static libraries then you may have to set `use_modular_headers!` globally in your Podfile, or specify `:modular_headers => true` for particular dependencies.

Then run the following command:

```bash
$ pod install
```

## Livestream

```swift
let broadcaster = UZBroadcastViewController()
let config = UZBroadcastConfig(cameraPosition: .front, videoResolution: ._720, videoBitrate: ._3000, videoFPS: ._30, audioBitrate: ._128Kbps, audioSampleRate: ._44_1khz, adaptiveBitrate: true)
broadcaster.prepareForBroadcast(config: config)
//...
broadcaster.startBroadcast(broadcastURL: BROADCAST_URL, streamKey: STREAM_KEY)
present(broadcaster, animated: true, completion: nil)
```

## Livestream with BeautyFilter

BeautyFilter uses GPUImage, so we need to use another approach:

```swift
let broadcaster = UZGPUBroadcastViewController()
broadcaster.filter.beautyLevel = 0.5 // 0.0 ... 1.0
broadcaster.filter.brightLevel = 0.5 // 0.0 ... 1.0
broadcaster.filter.toneLevel = 0.5 // 0.0 ... 1.0

let config = UZBroadcastConfig(cameraPosition: .front, videoResolution: ._720, videoBitrate: ._3000, videoFPS: ._30, audioBitrate: ._128Kbps, audioSampleRate: ._44_1khz, adaptiveBitrate: true)
broadcaster.prepareForBroadcast(config: config)
//...
broadcaster.startBroadcast(broadcastURL: BROADCAST_URL, streamKey: STREAM_KEY)
present(broadcaster, animated: true, completion: nil)
```

## Screen broadcast

```swift
let broadcaster = UZScreenBroadcast()
let config = UZBroadcastConfig(cameraPosition: .front, videoResolution: ._720, videoBitrate: ._3000, videoFPS: ._30, audioBitrate: ._128Kbps, audioSampleRate: ._44_1khz, adaptiveBitrate: true)
broadcaster.prepareForBroadcast(config: config)
//broadcaster.isMicrophoneEnabled = true
//broadcaster.isCameraEnabled = true
broadcaster.startBroadcast(broadcastURL: BROADCAST_URL, streamKey: STREAM_KEY)
```

Remember to add these usage description keys into `Info.plist` file:
```xml
<key>NSCameraUsageDescription</key>
<string>App needs access to camera for broadcasting</string>
<key>NSMicrophoneUsageDescription</key>
<string>App needs access to microphone for broadcasting</string>
```

## Network SpeedTest
To determine your upload speed before setting the right configuration for broadcasting, use this:
```swift
let url = URL(string: "https://beta.speedtest.net/api/js/servers?engine=js") // set your own upload server here
UZSpeedTest.shared.testUploadSpeed(url!, fileSize: 50_000_000, timeout: 10) { [weak self] current, average in
  print("Current: \(current.pretty) - Average: \(average.pretty)")
} final: { [weak self] result in
  switch result {
    case .value(let speed):
      let resultString = "Upload Speed: \(speed.pretty)"
      print(resultString)
      break
    case .error(let error):
      print("Speed test error: \(error)")
      break
  }
}
```

Or to get current broadcasting speed, do as following:
```swift
let screenBroadcaster = UZScreenBroadcast()
screenBroadcaster.delegate = self // self = YourViewController

let broadcastVC = UZBroadcastViewController()
broadcastVC.delegate = self // self = YourViewController

extension YourViewController: RTMPStreamDelegate {
	
  func rtmpStream(_ stream: RTMPStream, didStatics connection: RTMPConnection) {
    // print("Current Speed: \(Speed(bytes: Int64(connection.currentBytesOutPerSecond), seconds: 1).pretty)")
  }
  
  func rtmpStream(_ stream: RTMPStream, didPublishInsufficientBW connection: RTMPConnection) {
  }
	
  func rtmpStream(_ stream: RTMPStream, didPublishSufficientBW connection: RTMPConnection) {
  }
	
  func rtmpStream(_ stream: RTMPStream, didOutput video: CMSampleBuffer) {
  }
	
  func rtmpStream(_ stream: RTMPStream, didOutput audio: AVAudioBuffer, presentationTimeStamp: CMTime) {
  }
	
  func rtmpStreamDidClear(_ stream: RTMPStream) {
  }
	
}
```

## Reference
[API Reference](https://uizaio.github.io/uiza-ios-broadcast-sdk/)

## Support
namnh@uiza.io

## License
UZBroadcast is released under the BSD license. See [LICENSE](https://github.com/uizaio/uiza-sdk-broadcast-ios/blob/master/LICENSE) for details.
