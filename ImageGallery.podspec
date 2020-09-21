#
# Be sure to run `pod lib lint ImageGallery.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ImageGallery'
  s.version          = '1.1.1'
  s.summary          = 'image gallery ui component'
  s.homepage         = 'https://github.com/FabitMobile/ImageGallery.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'fabit_mobile' => 'aleksandr.zherebtsov@gorparkovki.ru' }
  s.source           = { :git => 'https://github.com/FabitMobile/ImageGallery.git', :tag => s.version.to_s }
  s.swift_version     = '5.2'
  s.ios.deployment_target = '9.0'

  s.source_files = 'ImageGallery/Source/**/*'

  s.dependency 'PINRemoteImage', '~> 3.0'

end