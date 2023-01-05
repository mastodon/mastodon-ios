# How it works
The app is currently build for iOS and iPadOS. We use the MVVM architecture to construct the whole app. Some design detail may not be the best practice. And any suggestions for improvements are welcome.

## Data
A typical status timeline fetches results from the database using a predicate that fetch the active account's entities. Then data source dequeues an item then configure the view. Likes many other MVVM applications. The app binds the Core Data entity to view via Combine publisher. Because the RunLoop dispatch drawing on the next loop. So we could return quickly. 

## Layout
A timeline has many posts and each post has many components. For example avatar, name, username, timestamp, content, media, toolbar and e.t.c. The app uses `AutoLayout` with `UIStackView` to place it and control whether it should hide or not. 

## Performance
Although it's easily loading timeline with hundreds of thousands of entities due to the Core Data fault mechanism. Some old devices may have slow performance when I/O bottleneck. There are three potential profile chances for entities: 
- preload fulfill 
- layout in background
- limit the data fetching

## SwiftUI
Some view models already migrate to `@Published` annotated output. It's future-proof support for SwiftUI. There are some views already transformed to `SwiftUI` likes `MastodonRegisterView` and `ReportReasonView`.

# Take it apart 
## Targets
The app builds with those targets:

- Mastodon: the app itself
- NotificationService: E2E push notification service
- ShareActionExtension: iOS share action
- MastodonIntent: Siri shortcuts

## MastodonSDK
There is a self-hosted Swift Package that contains the common libraries to build this app. 

- CoreDataStack: Core Data model definition and util methods
- MastodonAsset: image and font assets
- MastodonCommon: store App Group ID
- MastodonCore: the logic for the app
- MastodonExtension: system API extension utility
- MastodonLocalization: i18n resources
- MastodonSDK: Mastodon API client
- MastodonUI: App UI components

#### CoreDataStack
App uses Core Data as the backend to persist all entitles from the server. So the app has the capability to keep the timeline and notifications. Another reason for using a database is it makes the app could respond to entity changes between different sources. For example, a user could skim in the home timeline and then interact with the same post on other pages with favorite or reblog action. Core Data will handle the property modifications and notify the home timeline to update the view.

To simplify the database operations. There is only one persistent store for all accounts. We use `domain` to identify entity for different servers (a.k.a instance). Do not mix the `domain` with the Mastodon remote server name. For example. The domain is `mastodon.online` whereever the post (e.g. post come from `mstdn.jp`) and friends from for the account sign in `mastodon.online`. Also, do not only rely on `id` because it has conflict potential between different `domain`. The unique predicate is `domain` + `id`.

The app use "One stack, two context" setup. There is one main managed object context for UI displaying and another background managed context for entities creating and updating. We assert the background context performs in a queue. Also, the app could accept mulitple background context model. Then the flag `-com.apple.CoreData.ConcurrencyDebug 1` will be usful.

###### How to create a new Entity
First, select the `CoreData.xcdatamodeld` file and in menu `Editor > Add Model Version…` to create a new version. Make sure active the new version in the inspect panel. e.g. `Model Version. Current > "Core Data 5"`

Then use the `Add Entity` button create new Entity. 
1. Give a name in data model inspect panel. 
2. Also, set the `Module` to `CoreDataStack`. 
3. Set the `Codegen` to  `Manual/None`. We use `Sourery` generates the template code.
4. Create the `Entity.swift` file and declear the properties and relationships.

###### How to add or remove property for Entity
We using the Core Data lightweight migration. Please check the rules detail [here](https://developer.apple.com/documentation/coredata/using_lightweight_migration). And keep in mind that we using two-way relationship. And a relationship could be one-to-one, one-to-many/many-to-one. 

Tip: 

Please check the `Soucery` and use that generates getter and setter for properties and relationships. It's could save you time. To take the benefit from the dynamic property. We can declare a raw value property and then use compute property to construct the struct we want (e.g. `Feed.acct`). Or control the primitive by hand and declare the mirror type for this value (e.g `Status.attachments`).

###### How to persist the Entity
Please check the `Persistence+Status.swift`. We follow the pattern: migrate the old one if exists. Otherwise, create a new one. (Maybe some improvements could be adopted?)

#### MastodonAsset
Sourcery powered assets package.

#### MastodonCommon
Shared code for preference and configuration.

### MastodonCore
The core logic to drive the app.

#### MastodonExtension
Utility extension codes for SDK.

#### MastodonLocalization
Sourcery powered i18n package.

#### MastodonSDK
Mastodon API wrapper with Combine style API.

#### MastodonUI
Mastodon app UI components.

## NotificationService
Mastodon server accepts push notification register and we use the [toot-relay](https://github.com/DagAgren/toot-relay) to pass the server notifications to APNs. The message is E2E encrypted. The app will create an on-device private key for notification and save it into the keychain.

When the push notification is incoming. iOS will spawn our NotificationService extension to handle the message. At that time the message is decrypted and displayed as a banner or in-app silent notification event when the app is in the foreground. All the notification count and deep-link logic are handled by the main app.

## ShareActionExtension
The iOS Share Extension allows users to share links or media from other apps. The app uses the same implementation for the main app and the share extension. Then different is less available memoery for extension so maybe some memory bounded task could crash the app. (Plesae file the issue)

## MastodonIntent
iOS Siri shortcut supports. It allows iOS directly publish posts via Shortcut without app launching.
