#
# Be sure to run `pod lib lint Scoop.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Scoop'
  s.version          = '1.0.3'
  s.summary          = 'Scoop is simply made for downloading files and automatically unzip downloaded files.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
                        Scoop is simply made for downloading files. And the downloaded files that can be unzip will be automatically unzipped.
                       DESC

  s.homepage         = 'https://github.com/silexKhan/Scoop'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'silexKhan' => 'realsilex@naver.com' , 'JakyungYoon' => 'jakyung8@naver.com'}
  s.source           = { :git => 'https://github.com/silexKhan/Scoop.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '11.0'

  s.source_files = 'Scoop/Classes/**/*'
  
  # s.resource_bundles = {
  #   'Scoop' => ['Scoop/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.ios.dependency 'SSZipArchive'
end
