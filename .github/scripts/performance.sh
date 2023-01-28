#!/bin/bash

set -eo pipefail

SCHEME="${SCHEME:-Release}"
DERIVED_DATA_PATH="./build/"
ARCHIVE_PATH="./build/Archives/${SCHEME}.xcarchive"

xcrun xcodebuild clean \
    -workspace Mastodon.xcworkspace \
    -scheme Mastodon \
    -configuration "${SCHEME}"

# Build test bundle
xcrun xcodebuild build-for-testing \
    -workspace Mastodon.xcworkspace \
    -scheme Mastodon \
    -configuration "${SCHEME}" \
    -destination "generic/platform=iOS" \
    -parallelizeTargets \
    -showBuildTimingSummary \
    -derivedDataPath "${DERIVED_DATA_PATH}"

# Archive app
xcrun xcodebuild archive \
    -workspace Mastodon.xcworkspace \
    -scheme Mastodon \
    -configuration "${SCHEME}" \
    -destination "generic/platform=iOS" \
    -parallelizeTargets \
    -showBuildTimingSummary \
    -derivedDataPath "${DERIVED_DATA_PATH}"\
    -archivePath "${ARCHIVE_PATH}"

# Copy Linkmap files
mkdir "./build/Archives/${SCHEME}.xcarchive/Linkmaps"
find ./build -iname *-LinkMap-*.txt -exec cp "{}" "./build/Archives/${SCHEME}.xcarchive/Linkmaps/"  \;

# Copy Performance test files
mkdir "./build/Archives/${SCHEME}.xcarchive/EmergePerfTests"
cp "./build/Build/Products/Release-iphoneos/MastodonUITests-Runner.app/PlugIns/MastodonUITests.xctest" "./build/Archives/${SCHEME}.xcarchive/EmergePerfTests/"

# Create Performance Test Setup
TEST_CASES_FILE="./build/Archives/${SCHEME}.xcarchive/EmergePerfTests/info.yaml"
touch "${TEST_CASES_FILE}"
TEST_PLAN="testClasses:"
TEST_PLAN="${TEST_PLAN}\n  - class: MastodonPerformanceTest"
TEST_PLAN="${TEST_PLAN}\n    spans:"
TEST_PLAN="${TEST_PLAN}\n      - didFinishLaunching"
echo -e $TEST_PLAN > $TEST_CASES_FILE