platform :ios, '14.0'

target 'Mastodon' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Mastodon

  # UI
  pod 'UITextField+Shake', '~> 1.2'
  pod 'XLPagerTabStrip', '~> 9.0.0'

  # misc
  pod 'SwiftGen', '~> 6.4.0'
  pod 'DateToolsSwift', '~> 5.0.0'
  pod 'Kanna', '~> 5.2.2'
  pod 'Sourcery', '~> 1.6.1'

  # DEBUG
  pod 'FLEX', '~> 4.4.0', :configurations => ['Debug', "Release Snapshot"]
  
  target 'MastodonTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'MastodonUITests' do
    # Pods for testing
  end

end

target 'AppShared' do 
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end
