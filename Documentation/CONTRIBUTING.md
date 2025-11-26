# Contributing

- File an issue to report a bug or feature request
- Translate the project in our [Crowdin](https://crowdin.com/project/mastodon-for-ios) project
- Make the Pull Request to contribute

## Bug Report
File an issue about the bug or feature request. Make sure you are installing the latest version of the app from TestFlight or App Store.

## Translation
[![Crowdin](https://badges.crowdin.net/mastodon-for-ios/localized.svg)](https://crowdin.com/project/mastodon-for-ios)

The app uses CrowdIn to crowdsource translations. Translations will update regularly via a GitHub action. Please request the language if it is not listed via an issue.

Note that we have switched the main app localizations from using `.strings` and `.stringsdict` files (and `swiftgen` to create typed accessors) to using `.xcstrings` (and a manually-maintained `L10nLookup` struct to provide the typed accessors).
- The typed accessors in the swiftgen-generated `L10n` struct are still in use in the app, but the file is no longer automatically updated and no new accessors should be added to it manually. As the accessors are replaced by new ones in the `L10nLookup` struct (hopefully with more meaningful argument names), they should be removed from the old `L10n` struct.

### To add new localized strings:

- Edit `MastodonSDK/Sources/MastodonLocalizations/Resources/Localizable.xcstrings` to add the new string:
    - The key should follow our hierarchical naming conventions as you will see in other entries. The key should not be the English string itself.
    - Add the English user-facing text corresponding to the new key.
    - If plural variation is required, use the context menu option "Vary by Plural" to add it.
- Add a typed accessor in the `L10nLookup` struct:
    - Its place in the hierarchy should match the key you created.
    - Any argument names should match those in the `.xcstrings` entry you created.
    - Static strings can be `let` constants (the device language cannot change without a restart). Strings with substitutions must be functions.
- Use the new typed strings by importing `MastodonLocalization` and using the `L10nLookup` struct.
    - The `L10nLookup` struct will return the proper localization if it is available or fallback to English if it is not.
    - If you see the key itself in the UI, that means the string was not found in the `.xcstrings` file. Check for typos.
    
### To modify translations:
- English translations can be updated by modifying them locally in the `.xcstrings` file with the Xcode editor and pushing the change to GitHub. See "To merge translations" below for next steps.
- Other languages' translations must be made through the CrowdIn interface and integrated into the app by merging the resulting PR. This is because the next time CrowdIn changes are merged, any locally-made changes to those values will be overwritten with the previous values.
- Changes to *keys* that have already been uploaded to CrowdIn are likely to cause problems with the CrowdIn integration, so try not to change them.

### To merge translations:
- If you have any new strings or changes to English translations, commit those changes and push them to GitHub. This will immediately trigger the `CrowdIn/Upload translations` GitHub action.
- Log in to CrowdIn and check the "Activity" tab to confirm that CrowdIn has received your updates.
- Manually trigger the `CrowdIn/Download translations` GitHub action to pull in any updated translations.
- Merge the resulting PR from `i18n/crowdin/translations`.

Note: The `.strings` files in `WidgetExtension`, `MastodonIntent`, and `InfoPlist` have not yet been converted to `.xcstrings`, but they also don't seem to have been included in the `swiftgen` workflow.

## Pull Request

You can create a pull request directly with small block code changes for bugfix or feature implementations. Before making a pull request with hundred lines of changes to this repository, please first discuss the change you wish to make via an issue. 

Also, there are lots of existing feature request issues that could be a good-first-issue discussing place.

Follow the git-flow pattern to make your pull request.

1. Ensure you have started a new branch based on the `develop` branch.
2. Write your changes and test them on **iPad and iPhone**.
3. Merge the `develop` branch into your branch then make a Pull Request. Please merge the branch and resolve any conflicts if `develop` updates. **Do not force push your commits.**
4. Make sure the permission for your fork is open to the reviewer. Code style fix, conflict resolution, and other changes may be committed by the reviewer directly.
5. Request a code review and wait for approval. The PR will be merged when it is approved.

## Documentation
The documentation for this app is listed under the [Documentation](../Documentation/) folder. We are also welcoming contributions for documentation.
