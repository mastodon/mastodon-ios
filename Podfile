platform :ios, '14.0'

target 'Mastodon' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Mastodon

  # UI
  pod 'UITextField+Shake', '~> 1.2'
  
  # misc
  pod 'SwiftGen', '~> 6.4.0'
  pod 'DateToolsSwift', '~> 5.0.0'
  pod 'Kanna', '~> 5.2.2'
  
  target 'MastodonTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'MastodonUITests' do
    # Pods for testing
  end

  target 'NotificationService' do 

  end

  target 'AppShared' do 

  end

end

plugin 'cocoapods-keys', {
  :project => "Mastodon",
  :keys => [
    "notification_endpoint",
    "notification_endpoint_debug"
  ]
}