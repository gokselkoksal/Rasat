Pod::Spec.new do |s|

  s.name         = "Rasat"
  s.version      = "2.0.0"
  s.summary      = "Broadcast messages using channels."
  s.description  = <<-DESC
                    Rasat is a simple pub-sub/observer pattern implementation in Swift.
                   DESC
  s.homepage     = "https://github.com/gokselkoksal/Rasat/"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author           = { "Göksel Köksal" => "gokselkoksal@gmail.com" }
  s.social_media_url = "https://twitter.com/gokselkk"

  s.swift_version = '5.1'
  s.ios.deployment_target     = "8.0"
  s.osx.deployment_target     = "10.10"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target    = "9.0"

  s.source       = { :git => "https://github.com/gokselkoksal/Rasat.git", :tag => "#{s.version}" }
  s.source_files = "Rasat/Sources", "Rasat/Sources/**/*.swift"

end
