# RecordableMetalView

[![CI Status](https://img.shields.io/badge/Pod-1.7.5-yellowgreen)](https://travis-ci.org/afsaredrisy/RecordableMetalView)
[![Version](https://img.shields.io/badge/Version-0.1.0-lightgrey)](https://cocoapods.org/pods/RecordableMetalView)
[![License](https://img.shields.io/badge/License-MIT-blue)](https://cocoapods.org/pods/RecordableMetalView)
[![Platform](https://img.shields.io/badge/Platform-Swift%205.0-green)](https://cocoapods.org/pods/RecordableMetalView)

We use  `MTKView`  to render custom videos and animations. MTKView does not provides direct support to record video.
The objective of this project is to provide easy and efficient way to directly record video + audio (Either with MIC source or Audio file). 

## Demo
![image](https://drive.google.com/uc?export=view&id=17JinR9YkwDPW_fN0EYS5ISUHTmmXSwoQ)

## Feature
* API to render CIImage directly on MTKView with 30 fps.
* Record video rendered on MetalView with MIC audio source. 
* Record video rendered on MetalView with Custom audio track.

## Example
To run the example project, clone the repo, and run `pod install` from the Example directory first.
In this example each frame from camera is being filtered and overlayed on a static image and then redered on `RecordableMetalView`. OnTapped button video recording will start, onTapped on stop button video recording will stop and will save in photo library.

## Requirements
- [x] Xcode 11.
- [x] Swift 5.
- [x] iOS 11 or higher.

## Installation
RecordableMetalView is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:
```ruby
pod 'RecordableMetalView'
```

## Usage

### Creating  RecordableMetalView (Storyboard Implementation).
Create a `MTKView` from object library and set `custom class`  of `MTKView`  to be `RecordableMetalView ` 
![image](https://drive.google.com/uc?export=view&id=1Ivi9hLGiczXxxZt595ynLq2i0ukx-Pgq)

Next step is to create an outlet of this view to your `ViewController` class by draging mouse from MTKView to `ViewController` + holding `control` key. 

```swift
@IBOutlet weak var metalView: RecordableMetalView!
```

### Render or Draw CIImage on RecordableMetalView

To render CIImage on RecordableMetalView you can directly call `public func draw(ciimage: CIImage)` of  RecordableMetalView class.

#### Example.
```swift 
//make sure your project image assets has image with name 'bgimg'
let image = UIImage(named: "bgimg")
let ciimage = CIImage(cgImage: (image?.cgImage)!)
...

metalView.draw(ciimage: ciimage)
```

### Setting up RecordableMetalView callback delegate.

You need implement `RecordableMetalDelegate` inorder to get callback on recording events like  start and stop. for simplicity just implement `RecordableMetalDelegate` in your ViewController and set `metalView.recordingDelegate = self`.

```swift
class ViewController: UIViewController, RecordableMetalDelegate{

@IBOutlet weak var metalView: RecordableMetalView!
override func viewDidLoad() {
    super.viewDidLoad()
    metalView.recordingDelegate = self
}

//MARK: RecordableMetalDelegate callback methods
func didCompleteRecording(url: URL) {
    print("Completed at \(url)")
}
func didFailRecording(error: Error) {
    print("Error: \(error)")
}

}
...
```


### Recording with MIC Audio source.

To record your custom video rendered on `RecordableMetalView` with audio from MIC into `MP4` file use the following call. 
```swift
metalView.startVideoRecoding()
```

To stop recording make a call to:
```swift
metalView.stopVideoRecording()
```
Once you stop recording one of `RecordableMetalDelegate` method will invoke. `didCompleteRecording(url: URL)` will invoke if recording successfully finished. `url` will be of output file in document directory of your application.

### Recording with custom audio file
To record your custom video rendered on `RecordableMetalView` with audio source explicit file use the following call.

```swift
metalView.startVideoRecoding(backGroundAudioUrl: AUDIO_FILE_URL)
```
To stop recording make a call to:
```swift
metalView.stopVideoRecording()
```
Once you stop recording one of `RecordableMetalDelegate` method will invoke. `didCompleteRecording(url: URL)` will invoke if recording successfully finished. `url` will be of output file in document directory of your application.

## Thank You
A special thank for using RecordableMetalView,  Your support is appreciated! if you want to make this library better. If you'd like to contribute, please feel free to create a PR.

## Author
Afsar Ahamad. afsaredrisy@gmail.com
## License
RecordableMetalView is available under the MIT license. See the LICENSE file for more info.
