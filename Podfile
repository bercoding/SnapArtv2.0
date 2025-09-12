platform :ios, '15.0'

# Tắt Swift Package Manager để tránh xung đột
install! 'cocoapods', :disable_input_output_paths => true

# Xác định workspace
workspace 'SnapArtV2-1'

# Cấu hình chung cho các pods
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = ''
      config.build_settings['VALID_ARCHS'] = 'arm64 arm64e x86_64'
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
    end
  end
end

target 'SnapArtV2-1' do
  # Sử dụng dynamic frameworks
  use_frameworks!
  
  # Promises dependency (giải quyết lỗi FBLPromises)
  pod 'PromisesObjC'
  # MediaPipe Face Mesh dependencies
  pod 'MediaPipeTasksVision'
  # UI dependencies
  pod 'SnapKit'           # Auto layout
  pod 'Kingfisher'        # Image loading & caching
  
  # Reactive programming
  pod 'RxSwift'
  pod 'RxCocoa'
  #Google Admob 
  pod 'Google-Mobile-Ads-SDK'
end
