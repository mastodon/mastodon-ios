#!/bin/bash

set -eo pipefail

SCHEME="${SCHEME:-Mastodon}"
ARCHIVE_PATH="./build/Archives/${SCHEME}.xcarchive}"

xcrun xcodebuild clean \
    -workspace Mastodon.xcworkspace \
    -scheme Mastodon \
    -configuration "Debug"

xcrun xcodebuild archive \
    -workspace Mastodon.xcworkspace \
    -scheme Mastodon \
    -configuration "${SCHEME}" \
    -destination "generic/platform=iOS Simulator" \
    -parallelizeTargets \
    -showBuildTimingSummary \
    -archivePath "${ARCHIVE_PATH}"