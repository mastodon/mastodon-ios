# Setup

## Requirements

- Xcode 16+
- Swift 5.7+
- iOS 17.0+

Install the latest version of Xcode from the App Store or Apple Developer Download website. Also, we assert you have the [Homebrew](https://brew.sh) package manager.  

This guide may not suit your machine and actually setup procedure may change in the future. Please file an issue or open a Pull Request if there are any problems.

### Swiftgen and Sourcery

This app uses [SwiftGen](https://github.com/SwiftGen/SwiftGen) and [Sourcery](https://github.com/krzysztofzablocki/Sourcery) for Code Generation.

> [!NOTE]
> Both tools are optional. Using the following command will install them system wide:

```zsh
brew install swiftgen
brew install sourcery
```

```zsh
# install the rbenv
brew install rbenv

# configure the terminal
which ruby
# > /usr/bin/ruby
echo 'eval "$(rbenv init -)"' >> ~/.zprofile
source ~/.zprofile
which ruby
# > /Users/mainasuk/.rbenv/shims/ruby

# restart the terminal

# install ruby (we use the version defined in .ruby-version)
rbenv install

# install gem dependencies
bundle install
```

## Bootstrap

```zsh

# open project
xed .
```

The app requires the `App Group` capability. To make sure it works for your developer membership. Please check [AppSecret.swift](../MastodonSDK/Sources/MastodonCore/AppSecret.swift) file and set another unique `groupID` and update `App Group` settings.

#### Push Notification (Optional)

The app is compatible with [toot-relay](https://github.com/DagAgren/toot-relay) APNs. The push notification endpoint is set in AppSecret.swift.

Please check the [Establishing a Certificate-Based Connection to APNs
](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_certificate-based_connection_to_apns) document to generate the certificate and exports the p12 file.

Note: 
Please check and set the `notification.Topic` to the app BundleID in [toot-relay.go](https://github.com/DagAgren/toot-relay/blob/f9d6894040509881fee845972cd38ec6cd8f5a11/toot-relay.go#L112). The server needs use a reverse proxy to port this relay on 443 port with valid domain and HTTPS certificate.

## Start

1. Open `Mastodon.xcodeproj` 
2. Wait for the Swift Package Dependencies to be resolved. 
2. Check the signing settings make sure to choose a team. [More info…](https://help.apple.com/xcode/mac/current/#/dev23aab79b4)
3. Select `Mastodon` scheme and device then run it. (Command + R)

## What's next

We welcome contributions! And if you have an interest to contribute code, [here is a document](How-it-works.md) that describes the app architecture and what tech stack it uses.
