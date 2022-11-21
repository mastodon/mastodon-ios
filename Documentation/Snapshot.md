# Mastodon App Store Snapshot Guide
This documentation is a guide to create snapshots for App Store. The outer contributor could ignore this.

## Prepare toolkit 
The app use the Xcode UITest generate snapshots attachments. Then use the `xcparse` tool extract the snapshots. 

```zsh
# install xcparse from Homebrew
brew install chargepoint/xcparse/xcparse
```
## How it works
We use `xcodebuild` CLI tool to trigger UITest. 

Set the `name` in `-destination` option to add device for snapshot. For example:
`-destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch) (5th generation)' \`

You can list the available simulators:
```zsh
# list the destinations
xcodebuild \
  test \
  -showdestinations \
  -derivedDataPath '~/Downloads/MastodonBuild/Derived' \
  -workspace Mastodon.xcworkspace \
  -scheme 'Mastodon - Snapshot'

# output
Available destinations for the "Mastodon - Snapshot" scheme:
		{ platform:iOS Simulator, id:7F6D7727-AD49-4B79-B6F5-AEC538925576, OS:15.2, name:iPad (9th generation) }
		{ platform:iOS Simulator, id:BEB9533C-F786-40E6-8C38-248F6A11FC37, OS:15.2, name:iPad Air (4th generation) }
    …
```

#### Note:
Multiple lines for destination will dispatches the parallel snapshot jobs.


## Login before make snapshots
This script trigger the `MastodonUITests/MastodonUISnapshotTests/testSignInAccount` test case to sign-in the account. The test case may wait for 2FA code or email code. Please input it if needed. Also, you can skip this and sign-in the test account manually.

Replace the `<Email>` and `<Password>` for test account.
```zsh
# build and run test case for auto sign-in
TEST_RUNNER_login_domain='<Domain>' \
  TEST_RUNNER_login_email='<Email>' \
  TEST_RUNNER_login_password='<Password>' \
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

## Take and extract snapshots

### 1. Setup status bar
```zsh
# boot devices
xcrun simctl boot 'iPhone 8 Plus'
xcrun simctl boot 'iPhone 13 Pro Max'
xcrun simctl boot 'iPad Pro (12.9-inch) (5th generation)'

# setup magic status bar
xcrun simctl status_bar 'iPhone 13 Pro Max' override --time "9:41" --batteryState charged --batteryLevel 100
xcrun simctl status_bar 'iPhone 8 Plus' override --time "9:41" --batteryState charged --batteryLevel 100
xcrun simctl status_bar 'iPad Pro (12.9-inch) (5th generation)' override --time "9:41" --batteryState charged --batteryLevel 100
```

### 2. Take snapshots
The `TEST_RUNNER_` prefix will sets env value into test runner. 

```zsh
# take snapshots
TEST_RUNNER_login_domain='<domain.com>' \
  TEST_RUNNER_login_email='<email>' \
  TEST_RUNNER_login_password='<email>' \
  TEST_RUNNER_thread_id='<thread_id>' \
  TEST_RUNNER_profile_id='<profile_id>' \
  xcodebuild \
  test \
  -derivedDataPath '~/Downloads/MastodonBuild/Derived' \
  -workspace Mastodon.xcworkspace \
  -scheme 'Mastodon - Snapshot'  \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 13 Pro Max' \
  -destination 'platform=iOS Simulator,name=iPhone 8 Plus' \
  -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch) (5th generation)' \
  -test-iterations 3 \
  -retry-tests-on-failure \
  -testPlan 'AppStoreSnapshotTestPlan'

# output:
Test session results, code coverage, and logs:
	/Users/Me/Downloads/MastodonBuild/Derived/Logs/Test/Test-Mastodon - Snapshot-2022.03.03_18-00-38-+0800.xcresult

** TEST SUCCEEDED **
```

#### Note:
Add `-only-testing:MastodonUITests/MastodonUISnapshotTests/testSnapshot…` to run specific test case.

| Task                | key            | value                                                 |
| ------------------- | -------------- | ----------------------------------------------------- |
| testSignInAccount   | login_domain   | The server domain for user login                      |
| testSignInAccount   | login_email    | The user email for login                              |
| testSignInAccount   | login_password | The user password for login                           |
| testSnapshotThread  | thread_id      | The ID for post which used for thread scene snapshot  |
| testSnapshotProfile | profile_id     | The ID for user which used for profile scene snapshot |

### 3. Extract snapshots
Use `xcparse screenshots <path_for_xcresult> <path_for_destination>` extracts snapshots.

```zsh
# scresult path for previous test case 
xcparse screenshots '<path_for_xcresult>' ~/Downloads/MastodonBuild/Screenshots/

# output
100% [============]
🎊 Export complete! 🎊

# group
cd ~/Downloads/MastodonBuild/Screenshots/
mkdir 'iPhone 8 Plus' 'iPhone 13 Pro Max' 'iPad Pro (12.9-inch) (5th generation)'
find . -name "*iPad*" -type file -print0 | xargs -0 -I {} mv {} './iPad Pro (12.9-inch) (5th generation)'   
find . -name "*iPhone 8*" -type file -print0 | xargs -0 -I {} mv {} './iPhone 8 Plus'   
find . -name "*iPhone 13*" -type file -print0 | xargs -0 -I {} mv {} './iPhone 13 Pro Max'   

```
