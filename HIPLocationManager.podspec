Pod::Spec.new do |s|
  s.name         = "HIPLocationManager"
  s.version      = "1.0.0"
  s.summary      = "Block based iOS framework for handling user location detection. Supports both iOS7 and iOS8 and saves you time by handling the different permission requirements."
  s.homepage     = "https://github.com/Hipo/HIPLocationManager"
  s.license      = { :type => 'Apache', :file => 'LICENSE' }
  s.authors      = { "Taylan Pince" => "taylan@hipolabs.com" }
  s.source       = { :git => "https://github.com/Hipo/HIPLocationManager.git", :tag => "1.0.0" }
  s.platform     = :ios, '7.0'
  s.source_files = 'HIPLocationManager/*.{h,m}'
  s.requires_arc = true
end
