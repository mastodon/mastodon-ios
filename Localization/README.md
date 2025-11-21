# Localization
[![Crowdin](https://badges.crowdin.net/mastodon-for-ios/localized.svg)](https://crowdin.com/project/mastodon-for-ios)

We use Crowdin for translations and some automation.

## How to contribute

### Help with translations

Head over [Crowdin][crowdin-mastodon-ios] for that. To help with translations, select your language and translate :-) If your language is not in the list, please feel free to [open a topic on Crowdin](crowdin-mastodon-ios-discussions).

Please note: You need to have an account on Crowdin to help with translations.

### Add new strings

Developers can add new strings following the guidelines in `Documentation/CONTRIBUTING.md`.

## How to update translations

If there are new translations, Crowdin pushes new commits to a branch called `l10n_develop` and creates a new Pull Request.

To update or add new translations, merge the PR with `l10n_develop` into `develop`. It's usually called `New Crowdin Updates`

[crowdin-mastodon-ios]: https://crowdin.com/project/mastodon-for-ios
[crowdin-mastodon-ios-discussions]: https://crowdin.com/project/mastodon-for-ios/discussions
