Pod::Spec.new do |s|
  s.name             = 'mask_detector'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.platform         = :ios, '15.5'
  s.swift_version    = '5.0'

  s.resource_bundles = {
    'mask_detector' => ['Resources/**/*']
  }

  s.dependency 'Flutter'
  s.dependency 'TensorFlowLiteSwift', '~> 2.14.0'

  # Merged into a single pod_target_xcconfig block
  s.pod_target_xcconfig = {
    'DEFINES_MODULE'                       => 'YES',
    'OTHER_LDFLAGS'                        => '-framework TensorFlowLiteC -all_load',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }

  s.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }
end