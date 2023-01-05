# Localization
[![Crowdin](https://badges.crowdin.net/mastodon-for-ios/localized.svg)](https://crowdin.com/project/mastodon-for-ios)

We use Crowdin for translations and some automation.

## How to contribute

### Help with translations

Head over [Crowdin][crowdin-mastodon-ios] for that. To help with translations, select your language and translate :-) If your language is not in the list, please feel free to [open a topic on Crowdin](crowdin-mastodon-ios-discussions).

Please note: You need to have an account on Crowdin to help with translations.

### Add new strings

This is mainly for developers.

1. Add new strings in `Localization/app.json` **and** the `Localizable.strings` for English.
2. Run `swiftgen` to generate the `Strings.swift`-file **or** have Xcode build the app (`swiftgen` is a Build phase, too).
3. Use `import MastodonLocalization` and its (new) `L10n`-enum and its properties where ever you need them in the app.
4. Once the updated `Localization/app.json` hits `develop`, it gets synced to Crowdin, where people can help with translations. `Localization/app.json` must be a valid json.

## How to update translations

If there are new translations, Crowdin pushes new commits to a branch called `l10n_develop` and creates a new Pull Request. Both, the branch and the PR might be updated once an hour. The project itself uses a script to generate the various `Localizable.strings`-files etc. for Xcode.

To update or add new translations, the workflow is as follows:

1. Merge the PR with `l10n_develop` into `develop`. It's usually called `New Crowdin Updates`
2. Run `update_localization.sh` on your computer.
3. Commit the changes and push `develop`.

[crowdin-mastodon-ios]: https://crowdin.com/project/mastodon-for-ios
[crowdin-mastodon-ios-discussions]: https://crowdin.com/project/mastodon-for-ios/discussions
