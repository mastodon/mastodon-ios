# Mastodon


## Requirements

- Xcode 12.4+
- Swift 5.3+
- iOS 14.0+

## Setup
We needs the latest version Xcode from App Store. And install Cocoapods for dependency management.

### CocoaPods

#### For the Intel Mac

```zsh
# install cocoapods from Homebrew
brew install cocoapods
pod install
```

#### For the M1 Mac

```zsh
# install cocoapods from Homebrew
brew install cocoapods

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


## Acknowledgements

- [ActiveLabel](https://github.com/TwidereProject/ActiveLabel.swift)
- [AlamofireImage](https://github.com/Alamofire/AlamofireImage)
- [AlamofireNetworkActivityIndicator](https://github.com/Alamofire/AlamofireNetworkActivityIndicator)
- [Alamofire](https://github.com/Alamofire/Alamofire)
- [CommonOSLog](https://github.com/mainasuk/CommonOSLog)
- [DateToolSwift](https://github.com/MatthewYork/DateTools)
- [Kanna](https://github.com/tid-kijyun/Kanna)
- [Kingfisher](https://github.com/onevcat/Kingfisher)
- [SwiftGen](https://github.com/SwiftGen/SwiftGen)
- [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)
- [TwitterTextEditor](https://github.com/twitter/TwitterTextEditor)
- [UITextView-Placeholder](https://github.com/devxoul/UITextView-Placeholder)

## License
