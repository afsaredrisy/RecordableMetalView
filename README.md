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
- [*] Xcode 11.
- [*] Swift 5.
- [*] iOS 11 or higher.

## Installation

RecordableMetalView is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'RecordableMetalView'
```

## Author

Afsar Edrisy, afsaredrisz@icloud.com

## License

RecordableMetalView is available under the MIT license. See the LICENSE file for more info.
