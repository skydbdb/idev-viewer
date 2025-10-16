Pod::Spec.new do |s|
  s.name             = 'idev_viewer_package'
  s.version          = '0.0.1'
  s.summary          = 'IDev-based template viewer plugin for Flutter'
  s.description      = <<-DESC
IDev-based template viewer plugin for Flutter with 100% identical rendering across all platforms
                       DESC
  s.homepage         = 'https://idev.biz'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'IDev Team' => 'support@idev.biz' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
