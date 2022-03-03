# Mastodon App Store Snapshot Guide
This documentation is a guide to create snapshots for App Store. The outer contributor could ignore this.

## Prepare toolkit 
The app use the Xcode UITest generate snapshots attachments. Then use the `xcparse` tool extract the snapshots. 

```zsh
# install xcparse from Homebrew
brew install chargepoint/xcparse/xcparse
```
## Take Snapshots
We use `xcodebuild` CLI tool to trigger UITest. To change device for snapshot. 

Replace the `name` in `-destinatio` option to change device. For example:
`-destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch) (5th generation)' \`

```zsh
# list the destinations
xcodebuild \
  test \
  -showdestinations \
  -derivedDataPath '~/Downloads/MastodonBuild/Derived' \
  -workspace Mastodon.xcworkspace \
  -scheme 'Mastodon - Snapshot'
```

#### Auto-Login before make snapshots
This script trigger the `MastodonUITests/MastodonUISnapshotTests/testSignInAccount` test case to sign-in the account. The test case may wait for 2FA code or email code. Please input it if needed. Also, you can skip this and sign-in the test account manually.

Replace the `<Email>` and `<Password>` for test account.
```zsh
# build and run test case for auto sign-in
TEST_RUNNER_email='<Email>' \
  TEST_RUNNER_password='<Password>' \
  xcodebuild \
  test \
  -derivedDataPath '~/Downloads/MastodonBuild/Derived' \
  -workspace Mastodon.xcworkspace \
  -scheme 'Mastodon - Snapshot'  \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 13 Pro Max' \
  -destination 'platform=iOS Simulator,name=iPhone 8 Plus' \
  -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch) (5th generation)' \
  -testPlan 'AppStoreSnapshotTestPlan' \
  -only-testing:MastodonUITests/MastodonUISnapshotTests/testSignInAccount
```

Note: 
UITest may running silent. Open the Simulator.app to make the device display.

#### Take and extract snapshots
```zsh
# setup magic status bar
xcrun simctl status_bar 'iPhone 13 Pro Max' override --time "9:41" --batteryState charged --batteryLevel 100
xcrun simctl status_bar 'iPhone 8 Plus' override --time "9:41" --batteryState charged --batteryLevel 100
xcrun simctl status_bar 'iPad Pro (12.9-inch) (5th generation)' override --time "9:41" --batteryState charged --batteryLevel 100

# take snapshots
TEST_RUNNER_domain='<domain.com>' \
  TEST_RUNNER_username_snapshot='username@domain.com' \
  xcodebuild \
  test \
  -derivedDataPath '~/Downloads/MastodonBuild/Derived' \
  -workspace Mastodon.xcworkspace \
  -scheme 'Mastodon - Snapshot'  \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 13 Pro Max' \
  -destination 'platform=iOS Simulator,name=iPhone 8 Plus' \
  -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch) (5th generation)' \
  -testPlan 'AppStoreSnapshotTestPlan' \
  -only-testing:MastodonUITests/MastodonUISnapshotTests/testSnapshot

# output:
Test session results, code coverage, and logs:
	/Users/Me/Downloads/MastodonBuild/Derived/Logs/Test/Test-Mastodon - Snapshot-2022.03.03_18-00-38-+0800.xcresult

** TEST SUCCEEDED **
```

Use `xcparse screenshots <path_for_xcresult> <path_for_destination>` extracts snapshots.

```zsh
# scresult path for previous test case 
xcparse screenshots '<path_for_xcresult>' ~/Downloads/MastodonBuild/Screenshots/

# output
100% [============]
🎊 Export complete! 🎊
```
