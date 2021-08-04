platform :ios, '14.0'

target 'Mastodon' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Mastodon

  # UI
  pod 'UITextField+Shake', '~> 1.2'
  pod 'Texture', '~> 3.0.0', :configurations => ['ASDK - Debug', 'ASDK - Release']

  # misc
  pod 'SwiftGen', '~> 6.4.0'
  pod 'DateToolsSwift', '~> 5.0.0'
  pod 'Kanna', '~> 5.2.2'

  # DEBUG
  pod 'FLEX', '~> 4.4.0', :configurations => ['Debug', 'ASDK - Debug']
  
  target 'MastodonTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'MastodonUITests' do
    # Pods for testing
  end

end

target 'NotificationService' do 
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
end

target 'ShareActionExtension' do 
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
end

target 'MastodonIntent' do 
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
end

target 'AppShared' do 
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
end

plugin 'cocoapods-keys', {
  :project => "Mastodon",
  :keys => [
    "notification_endpoint",
    "notification_endpoint_debug"
  ]
}

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end