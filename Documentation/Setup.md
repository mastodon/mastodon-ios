# Setup

## Requirements

- Xcode 13+
- Swift 5.5+
- iOS 14.0+
- [Homebrew package manager](https://brew.sh)


Install the latest version of Xcode from the App Store or Apple Developer Download website as well as [Homebrew](https://brew.sh) from its website.

This guide may change in the future. Please [create an issue](https://github.com/mastodon/mastodon-ios/issues/new/choose) or [open a pull request](https://github.com/mastodon/mastodon-ios/blob/main/Documentation/CONTRIBUTING.md) if there are any problems.

## CocoaPods
The app uses [CocoaPods](https://cocoapods.org/) and [CocoaPods-Keys](https://github.com/orta/cocoapods-keys). Ruby Gems are managed through Bundler.

The M1 Mac needs a virtual ruby environment to work around compatibility issues.

#### Intel Mac

```zsh
gem install bundler
bundle install
```

#### M1 Mac

```zsh
# Install the rbenv package
brew install rbenv
which ruby
# > /usr/bin/ruby

# These instructions only work for ZSH (macOS default shell); adjust for your shell
echo 'eval "$(rbenv init -)"' >> ~/.zprofile
source ~/.zprofile

# Select a Ruby version to install
rbenv install --list

# Here we select the latest version in the 3.0.x series
rbenv install 3.0.4
rbenv global 3.0.4
which ruby
# > /Users/mainasuk/.rbenv/shims/ruby
ruby --version
# > ruby 3.0.4p208 (2022-04-12 revision 3fa771dded) [arm64-darwin22]

gem install bundler
bundle install
```

## Bootstrap

```zsh
# copy .env.sample to .env (see Push Notifications below)
cp .env.sample .env

# make a clean build
bundle install
bundle exec pod clean

# make install
bundle exec pod install --repo-update

# open workspace
open Mastodon.xcworkspace
```

The app requires the `App Group` capability. To make sure it works for your developer membership. Please check [AppSecret.swift](../AppShared/AppSecret.swift) file and set another unique `groupID` and update `App Group` settings.

#### Push Notification (Optional)
The app is compatible with [toot-relay](https://github.com/DagAgren/toot-relay) APNs. You can set your push notification endpoint via the `.env` file copied above. There are two endpoints which can be configured:
- NotificationEndpointRelease: for `RELEASE` usage
- NotificationEndpointDebug: for `DEBUG` usage

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