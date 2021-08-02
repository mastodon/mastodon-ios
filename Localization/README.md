# Localization
[![Crowdin](https://badges.crowdin.net/mastodon-for-ios/localized.svg)](https://crowdin.com/project/mastodon-for-ios)

Mastodon localization template file


## How to contribute?

Please use the [Crodwin](https://crowdin.com/project/mastodon-for-ios) to contribute. If your language is not in the list. Please feel free to open the issue.

## How to maintains

The project use a script to generate Xcode localized strings files.

```zsh
// enter workdir
cd Mastodon

// merge PR from Crowdin bot

// update resource
./update_localization.sh
```