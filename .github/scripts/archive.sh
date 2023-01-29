#!/bin/bash

set -eo pipefail

SCHEME="${SCHEME:-Mastodon}"
DERIVED_DATA_PATH="./build/"
ARCHIVE_PATH="./build/Archives/${SCHEME}.xcarchive"

xcrun xcodebuild clean \
    -workspace Mastodon.xcworkspace \
    -scheme Mastodon \
    -configuration "${SCHEME}"

xcrun xcodebuild archive \
    -workspace Mastodon.xcworkspace \
    -scheme Mastodon \
    -configuration "${SCHEME}" \
    -destination "generic/platform=iOS Simulator" \
    -parallelizeTargets \
    -showBuildTimingSummary \
    -derivedDataPath "${DERIVED_DATA_PATH}"\
    -archivePath "${ARCHIVE_PATH}"