#
#  Be sure to run `pod spec lint FFZQRCode.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|



  s.name         = "FFZQRCode"
  s.version      = "0.0.1"
  s.summary      = "QRCode scan like WeChar"


  s.homepage     = "https://github.com/feifeizhai/FFZQRCode"

  s.license      = "MIT"

  s.author             = { "FFZ" => "1019899485@qq.com" }
    s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/feifeizhai/FFZQRCode.git", :commit => "e38c58053f694011e25a3852ad5c566eaa68b211" }



  s.source_files  = "FFZQRCode", "FFZQRCode/**/*.{h,m}"
# s.exclude_files = "Classes/Exclude"
s.frameworks = "UIKit", "Foundation", "AVFoundation"
s.dependency "OpenCV"
s.dependency "Masonry"


end
