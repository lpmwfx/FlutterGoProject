Pod::Spec.new do |s|
  s.name             = 'go_engine'
  s.version          = '1.0.0'
  s.summary          = 'Go engine for Flutter app.'
  s.description      = <<-DESC
A Go engine that provides some backend functionality for the Flutter app.
                       DESC
  s.homepage         = 'https://example.com'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Your Name' => 'your.email@example.com' }
  s.source           = { :path => '.' }

  s.ios.deployment_target = '12.0'
  s.vendored_libraries = 'libengine_simulator.a'
  s.frameworks = 'Foundation', 'Security', 'CoreFoundation', 'UIKit', 'CoreGraphics', 'QuartzCore'
end