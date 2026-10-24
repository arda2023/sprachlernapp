#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint device_translation.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'device_translation'
  s.version          = '0.0.1'
  s.summary          = 'Local Apple Translation bridge for Sprachapp.'
  s.description      = <<-DESC
Local Apple Translation bridge for Sprachapp.
                       DESC
  s.homepage         = 'https://developer.apple.com/documentation/translation'
  s.license          = { :file => '../LICENSE' }
  s.author           = 'Sprachapp'
  s.source           = { :path => '.' }
  s.source_files = 'device_translation/Sources/device_translation/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'device_translation_privacy' => ['device_translation/Sources/device_translation/PrivacyInfo.xcprivacy']}
end
