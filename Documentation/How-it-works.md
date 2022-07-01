# How it works
App is currently build for iOS and iPadOS. We use the MVVM architecture to construct the whole app. 

## Targets
The app build with those targets:

- Mastodon: the app itself
- NotificationService: E2E push notification service
- ShareActionExtension: iOS share action
- MastodonIntent: Siri shortcuts
- AppShared: used for `cocoapods-keys` integration


## MastodonSDK
There is a self-hosted Swift Pacakge contains the common libraries to build this app. 

- CoreDataStack: Core Data model definition and util methods
- MastodonAsset: image and font assets
- MastodonCommon: store App Group ID
- MastodonExtension: system API extension utility
- MastodonLocalization: i18n resources
- MastodonSDK: Mastodon API client
- MastodonUI: App UI components

Some brief for important packets:

#### CoreDataStack
// TODO: