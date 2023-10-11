# Deployment

## Your Device

### As a Mastodon Collaborator WITH access to the Mastodon Apple Developer Program

To ensure you're able to build the App for your Device please create a `fastlane/devices.txt` and add your device's UDID.
You may use `fastlane/devices.text.example` as a starting point. Please note that fastlane expects you to use tabs in this file.

After adding your device please run `bundle exec fastlane ios register_devices` to add your device(s) to the Apple Develper Account.
Then run `bundle exec fastlane ios update_certificates` to re-generate the Codesigning Provisioning Profiles.

You should now be able to run the App using Xcode on your Device.

### As a Mastodon Contributor WITHOUT access to the Mastodon Apple Developer Program

To run the App on your Device you'll need to take care of Codesigning yourself by adjusting the App's Codesigning Settings in Xcode to your needs.

## App Store

We're using [Fastlane](https://fastlane.tools) to deploy the App to App Store Connect. Please see the [Fastlane README](../fastlane/README.md) on the available commands.
