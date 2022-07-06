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
App uses Core Data as the backend to persist all entitles from the server. So the app has the capability to keep the timeline and notifications. Another reason for using a database makes the app could responses entity changes between different sources. For example, a user could skim in the home timeline and then interact with the same post on other pages with favorite or reblog actions. Core Data will handle the property modifications and notify the home timeline to update the view.

The app use one stack two context Core Data setup. There is a main managed object context for UI displaying and a background context to persists entities creating and updating. We assert the background context performs in a queue. But should derive a new background context for long-time database operation to avoid concurrency persistent conflict issues.

#### NotificationService
Mastodon server accepts push notification register and we use the [toot-relay](https://github.com/DagAgren/toot-relay) to pass the server notifications to APNs. The message is E2E encrypted. The app will create an on-device private key for notification and save it into the keychain.

When the push notification is incoming. iOS will spawn our NotificationService extension to handle the message. At that time the message is decrypted and displayed as a banner or in-app silent notification event when the app is in the foreground. All the notification count and deep-link logic are handled by the main app.

#### ShareActionExtension
TBD