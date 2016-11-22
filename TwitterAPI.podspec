Pod::Spec.new do |s|
  s.name             = "TwitterAPI"
  s.version          = "0.4.0"
  s.summary          = "This Twitter framework is to both support the OAuth and Social.framework, can handle REST and Streaming API."
  s.description      = <<-DESC
                         Features
                         - Streaming API connection using the NSURLSession
                         - Both support the OAuth and Social.framework (iOS only)
                         - Both support the iOS and OSX
                       DESC
  s.homepage         = "https://github.com/s-aska/TwitterAPI"
  s.license          = 'MIT'
  s.author           = { "aska" => "s.aska.org@gmail.com" }
  s.social_media_url = "https://twitter.com/su_aska"
  s.source           = { :git => "https://github.com/s-aska/TwitterAPI.git", :tag => "#{s.version}" }

  s.ios.deployment_target = "9.0"
  s.osx.deployment_target = "10.10"
  s.requires_arc = true

  s.dependency 'OAuthSwift', '= 1.0.0'
  s.dependency 'MutableDataScanner'

  s.source_files = 'TwitterAPI/*.swift'
end
