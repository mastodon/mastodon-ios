source 'https://cdn.cocoapods.org/'
platform :ios, '14.0'

target 'Mastodon' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Mastodon

  # UI
  pod 'XLPagerTabStrip', '~> 9.0.0'

  # misc
  pod 'SwiftGen', '~> 6.6.2'
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

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
    # https://github.com/CocoaPods/CocoaPods/issues/11402#issuecomment-1201464693
    if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
      target.build_configurations.each do |config|
          config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      end
    end
  end
end
