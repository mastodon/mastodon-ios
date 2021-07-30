# Mastodon


## Requirements

- Xcode 12.5+
- Swift 5.3+
- iOS 14.0+

## Setup
We needs the latest version Xcode from App Store. And use Cocoapods for dependency management.

### CocoaPods

#### For the Intel Mac

```zsh
# install cocoapods from Homebrew
sudo gem install cocoapods
sudo gem install cocoapods-keys
pod install
```

#### For the M1 Mac

```zsh
# install cocoapods from Homebrew
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
- [swift-nio](https://github.com/apple/swift-nio)
- [SwiftGen](https://github.com/SwiftGen/SwiftGen)
- [SwiftUI-Introspect](https://github.com/siteline/SwiftUI-Introspect)
- [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)
- [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)
- [Tabman](https://github.com/uias/Tabman)
- [Texture](https://github.com/TextureGroup/Texture)
- [ThirdPartyMailer](https://github.com/vtourraine/ThirdPartyMailer)
- [TOCropViewController](https://github.com/TimOliver/TOCropViewController)
- [TwitterProfile](https://github.com/OfTheWolf/TwitterProfile)
- [UITextView-Placeholder](https://github.com/devxoul/UITextView-Placeholder)

## License
