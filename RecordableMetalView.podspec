#
# Be sure to run `pod lib lint RecordableMetalView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'RecordableMetalView'
  s.version          = '0.1.0'
  s.summary          = 'Provides easy and efficient ways to record video from MTKView'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
'We use MTKView to render custom videos and animations. MTKView does not provides direct support to record video. The objective of this project is to provide easy and efficient way to directly record video + audio (Either with MIC source or Audio file).'
                       DESC

  s.homepage         = 'https://github.com/afsaredrisy/RecordableMetalView'
   s.screenshots     = 'https://drive.google.com/uc?export=view&id=1nXWxL2r0jbDpO1ElljsVZhkPzrqljVxX'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Afsar Ahamad' => 'afsaredrisz@icloud.com' }
  s.source           = { :git => 'https://github.com/afsaredrisy/RecordableMetalView.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'
  s.source_files = 'Source/**/*'
  # s.resource_bundles = {
  #   'RecordableMetalView' => ['RecordableMetalView/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
   s.frameworks = 'UIKit', 'MetalKit', 'Metal', 'AssetsLibrary', 'AVKit', 'AVFoundation', 'Photos', 'QuartzCore'
  # s.dependency 'AFNetworking', '~> 2.3'
end
