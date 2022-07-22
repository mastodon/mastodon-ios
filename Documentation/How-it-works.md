# How it works
The app is currently built for iOS and iPadOS. We use the MVVM architecture to construct the whole app. Some design detail may not be the best practice and welcome any suggestions for improvements.

## Data
A typical status timeline fetches results from the database using a predicate that specifies active account-related entities displayed. Then table view data source dequeues an item to configure the view. Likes many other MVVM applications. The app binds the Core Data entity to view via Combine publisher. Because the RunLoop dispatch drawing on the next loop. So we could return quickly. 

## Layout
A timeline has many posts and each post has many components. For example avatar, name, username, timestamp, content, media, and toolbar. The app uses `AutoLayout` with `UIStackView` to place it and control whether it should hide or not. 

## Performance
Although it's easily loading timeline with hundreds of thousands of entities due to the Core Data fault mechanism. Some old devices may have slow performance when I/O bottleneck. There are two potential profile chances for entities preload fulfill and background drawing layout. 

## SwiftUI
Some view models already migrate to `@Published` annotated output. It's future-proof support for SwiftUI. There are some views already transformed to `SwiftUI` likes `MastodonRegisterView` and `ReportReasonView`.

# Take it apart 
## Targets
The app builds with those targets:

- Mastodon: the app itself
- NotificationService: E2E push notification service
- ShareActionExtension: iOS share action
- MastodonIntent: Siri shortcuts
- AppShared: SwiftPM dependency resolve


## MastodonSDK
There is a self-hosted Swift Package that contains the common libraries to build this app. 

- CoreDataStack: Core Data model definition and util methods
- MastodonAsset: image and font assets
- MastodonCommon: store App Group ID
- MastodonExtension: system API extension utility
- MastodonLocalization: i18n resources
- MastodonSDK: Mastodon API client
- MastodonUI: App UI components

#### CoreDataStack
App uses Core Data as the backend to persist all entitles from the server. So the app has the capability to keep the timeline and notifications. Another reason for using a database is it makes the app could respond to entity changes between different sources. For example, a user could skim in the home timeline and then interact with the same post on other pages with favorite or reblog actions. Core Data will handle the property modifications and notify the home timeline to update the view.

To simplify the database operations. There is only one persistent store for all accounts. We use `domain` to identify entity for different servers (a.k.a instance). Do not mix the `domain` with the Mastodon remote server name. The domain is `mastodon.online`  whatever the post (e.g. post at `mstdn.jp`) and friends from for an account sign in `mastodon.online`. Also, do not only rely on `id` because it has conflict potential in others `domain`.

The app use one stack two context Core Data setup. There is one main managed object context for UI displaying and another background managed context for entities creating and updating. We assert the background context performs in a queue. But derive a new background context for long-time database operation to avoid concurrency persistent conflict issues should be considered.

#### MastodonAsset
Sourcery powered assets packet.

#### MastodonCommon
Shared code for preference and configuration.

#### MastodonExtension
Utility extension codes for SDK.

#### MastodonLocalization
Sourcery powered i18n packet.

#### MastodonSDK
Mastodon API wrapper with Combine style API.

#### MastodonUI
Mastodon app UI components.

## NotificationService
Mastodon server accepts push notification register and we use the [toot-relay](https://github.com/DagAgren/toot-relay) to pass the server notifications to APNs. The message is E2E encrypted. The app will create an on-device private key for notification and save it into the keychain.

When the push notification is incoming. iOS will spawn our NotificationService extension to handle the message. At that time the message is decrypted and displayed as a banner or in-app silent notification event when the app is in the foreground. All the notification count and deep-link logic are handled by the main app.

## ShareActionExtension
The iOS Share Extension allows users to share links or media from other apps. The app uses the UIKit implementation. For simplifying we using the SwiftUI implementing a replica one but with fewer features.

## MastodonIntent
iOS Siri shortcut supports. It allows iOS directly publish posts via Shortcut without app launching.

## AppShared
A framework for SwiftPM packet dependency resolve. Also, for CocoaPods-Key integration but we migrate to Arkana now.
