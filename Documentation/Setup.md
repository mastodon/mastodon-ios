# Setup

## Requirements

- Xcode 13+
- Swift 5.5+
- iOS 14.0+


Intell the latest version of Xcode from the App Store or Apple Developer Download website. Also, we assert you have the [Homebrew](https://brew.sh) package manager.  

This guide may not suit your machine and actually setup procedure may change in the future. Please file the issue or Pull Request if there are any problems.

## CocoaPods
The app use [CocoaPods]() and [CocoaPods-Keys](https://github.com/orta/cocoapods-keys). The M1 Mac needs virtual ruby env to workaround compatibility issues.

#### Intel Mac

```zsh
sudo gem install cocoapods cocoapods-keys
```

#### M1 Mac

```zsh
# install the rbenv
brew install rbenv
which ruby
# > /usr/bin/ruby
echo 'eval "$(rbenv init -)"' >> ~/.zprofile
source ~/.zprofile
which ruby
# > /Users/mainasuk/.rbenv/shims/ruby

# select ruby
rbenv install --list
# here we use the latest 3.0.x version
rbenv install 3.0.3
rbenv global 3.0.3
ruby --version
# > ruby 3.0.3p157 (2021-11-24 revision 3fb7d2cadc) [arm64-darwin21]

sudo gem install cocoapods cocoapods-keys
```

## Bootstrap

```zsh
# make a clean build
sudo gem install cocoapods-clean
pod clean

# make install
pod install --repo-update

# open workspace
open Mastodon.xcworkspace
```

The CocoaPods-Key plugin will request the push notification endpoint. You can fufill the empty string and set it later. To setup the push notification. Please check section `Push Notification` below.

The app requires the `App Group` capability. To make sure it works for your developer membership. Please check [AppSecret.swift](../AppShared/AppSecret.swift) file and set another unique `groupID` and update `App Group` settings.

#### Push Notification (Optional)
The app is compatible with [toot-relay](https://github.com/DagAgren/toot-relay) APNs. You can set your push notification endpoint via Cocoapod-Keys. There are two endpoints:
- notification_endpoint: for `RELEASE` usage
- notification_endpoint_debug: for `DEBUG` usage

Please check the [Establishing a Certificate-Based Connection to APNs
](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_certificate-based_connection_to_apns) document to generate the certificate and exports the p12 file.

Note: 
Please check and set the `notification.Topic` to the app BundleID in [toot-relay.go](https://github.com/DagAgren/toot-relay/blob/f9d6894040509881fee845972cd38ec6cd8f5a11/toot-relay.go#L112). The server needs use a reverse proxy to port this relay on 443 port with valid domain and HTTPS certificate.

## Start
1. Open `Mastodon.xcworkspace` 
2. Wait for the Swift Package Dependencies resolved. 
2. Check the signing settings make sure to choose a team. [More info…](https://help.apple.com/xcode/mac/current/#/dev23aab79b4)
3. Select `Mastodon` scheme and device then run it. (Command + R)

## What's next

We welcome contributions! And if you have an interest to contribute codes. Here is a document that describes the app architecture and what's tech stack it uses.