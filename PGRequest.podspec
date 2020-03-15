#
# Be sure to run `pod lib lint PGRequest.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PGRequest'
  s.version          = '0.5.0'
  s.summary          = 'API Protocols'
  s.description      = "API Protocols for Alamofire and RxSwift"

  s.homepage         = 'https://github.com/ipagong/PGRequest'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ipagong' => 'ipagong.dev@gmail.com' }
  s.source           = { :git => 'https://github.com/ipagong/PGRequest.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '8.0'

  s.source_files = 'PGRequest/Classes/**/*'
  
  s.dependency 'Alamofire',   '~> 5.0'
  s.dependency 'RxCocoa',     '~> 5.0'
  s.dependency 'RxSwift',     '~> 5.0'
end
