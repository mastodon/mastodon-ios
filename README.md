# Mastodon
[![CI](https://github.com/mastodon/mastodon-ios/actions/workflows/main.yml/badge.svg)](https://github.com/mastodon/mastodon-ios/actions/workflows/main.yml) [![Crowdin](https://badges.crowdin.net/mastodon-for-ios/localized.svg)](https://crowdin.com/project/mastodon-for-ios)


<a href="https://apps.apple.com/us/app/mastodon-for-iphone/id1571998974?itsct=apps_box_badge&amp;itscg=30200" style="display: inline-block; overflow: hidden; border-top-left-radius: 13px; border-top-right-radius: 13px; border-bottom-right-radius: 13px; border-bottom-left-radius: 13px; width: 250px; height: 83px;"><img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-us?size=250x83&amp;releaseDate=1627603200&h=72b0c8495c2c0af1291efef280c4c2c1" alt="Download on the App Store" style="border-top-left-radius: 13px; border-top-right-radius: 13px; border-bottom-right-radius: 13px; border-bottom-left-radius: 13px; width: 250px; height: 83px;"></a>

## Requirements

- Xcode 12.5+
- Swift 5.3+
- iOS 14.0+

## Setup
We need the latest version of Xcode from App Store. And use Cocoapods for dependency management.

### CocoaPods

#### For the Intel Mac

```zsh
sudo gem install cocoapods
sudo gem install cocoapods-keys
pod install
```

#### For the M1 Mac

```zsh
sudo gem install cocoapods
sudo gem install cocoapods-keys

# pod install may not works on M1 Mac. Fix by install ffi
# ref: https://github.com/CocoaPods/CocoaPods/issues/10220
sudo arch -x86_64 gem install ffi

arch -x86_64 pod install
```

## Start

1. Open `Mastodon.xcworkspace` 
2. Wait the Swift Package Dependencies resolved. 
2. Check the signing settings make sure choose a team. [More info…](https://help.apple.com/xcode/mac/current/#/dev23aab79b4)
3. Select `Mastodon` scheme and run it.

#### Contributors
The app require the `App Group` capability. To make sure it works for your developer membership. Please check [AppName.swift](AppShared/AppName.swift) file and set another unique `groupID` and update `App Group` settings.

The app is compatible with [toot-relay](https://github.com/DagAgren/toot-relay) APNs. You can set your push notification endpoint via cocoapod-keys.


## Acknowledgements

- [AlamofireImage](https://github.com/Alamofire/AlamofireImage)
- [AlamofireNetworkActivityIndicator](https://github.com/Alamofire/AlamofireNetworkActivityIndicator)
- [Alamofire](https://github.com/Alamofire/Alamofire)
- [CommonOSLog](https://github.com/mainasuk/CommonOSLog)
- [CryptoSwift](https://github.com/krzyzanowskim/CryptoSwift)
- [DateToolSwift](https://github.com/MatthewYork/DateTools)
- [DiffableDataSources](https://github.com/ra1028/DiffableDataSources)
- [DifferenceKit](https://github.com/ra1028/DifferenceKit)
- [FLAnimatedImage](https://github.com/Flipboard/FLAnimatedImage)
- [FLEX](https://github.com/FLEXTool/FLEX)
- [FPSIndicator](https://github.com/MainasuK/FPSIndicator)
- [Fuzi](https://github.com/cezheng/Fuzi)
- [Kanna](https://github.com/tid-kijyun/Kanna)
- [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess.git)
- [Kingfisher](https://github.com/onevcat/Kingfisher)
- [MetaTextKit](https://github.com/TwidereProject/MetaTextKit)
- [Nuke-FLAnimatedImage-Plugin](https://github.com/kean/Nuke-FLAnimatedImage-Plugin)
- [Nuke](https://github.com/kean/Nuke)
- [Pageboy](https://github.com/uias/Pageboy#the-basics)
- [SDWebImage](https://github.com/SDWebImage/SDWebImage)
- [swift-collections](https://github.com/apple/swift-collections)
- [swift-nio](https://github.com/apple/swift-nio)
- [SwiftGen](https://github.com/SwiftGen/SwiftGen)
- [SwiftUI-Introspect](https://github.com/siteline/SwiftUI-Introspect)
- [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)
- [Tabman](https://github.com/uias/Tabman)
- [Texture](https://github.com/TextureGroup/Texture)
- [ThirdPartyMailer](https://github.com/vtourraine/ThirdPartyMailer)
- [TOCropViewController](https://github.com/TimOliver/TOCropViewController)
- [TwitterProfile](https://github.com/OfTheWolf/TwitterProfile)
- [UITextView-Placeholder](https://github.com/devxoul/UITextView-Placeholder)

## License

This project is released under the [GPL-3 License](./LICENSE). It is also dual-licensed to Apple for the purposes of publishing the app on the App Store. For this reason, any contributors are required to sign a Contributor License Agreement.
