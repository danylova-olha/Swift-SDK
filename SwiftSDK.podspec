Pod::Spec.new do |s|
  s.name         = "SwiftSDK"
  s.module_name  = "Backendless"
  s.version      = "0.0.1-b3"
  s.license      = { :type => 'MIT', :text => 'Copyright (c) 2013-2018 by Backendless Corp' }
  s.homepage     = "http://backendless.com"
  s.authors      = { 'Mark Piller' => 'mark@backendless.com', 'Olha Danylova' => 'olga@themidnightcoders.com' }
  s.summary      = "Backendless is a Mobile Backend and API Services Platform"
  s.description  = "Backendless is a development and a run-time platform. It helps software developers to create mobile and desktop applications while removing the need for server-side coding."
  s.swift_version = '4.2'

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'
  s.requires_arc = true
  s.source = { :git => 'https://github.com/Backendless/Swift-SDK.git', :tag => '0.0.1-b3' }
  s.source_files = "Sources/SwiftSDK/**/*.swift", "Sources/SwiftSDK/*.swift", "SwiftSDKTests/TestObjects/*.swift"
  s.dependency "SwiftyJSON"
  
end
