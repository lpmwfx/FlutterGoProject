Pod::Spec.new do |s|
  s.name             = 'go_engine'
  s.version          = '1.0.0'
  s.summary          = 'Go engine for Flutter app.'
  s.homepage         = 'http://example.com'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Your Name' => 'your.name@example.com' }
  s.source           = { :git => '', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'
  s.vendored_frameworks = 'libengine.xcframework'
  s.pod_target_xcconfig = { 'OTHER_LDFLAGS' => '-framework libengine' }
end