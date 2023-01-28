#!/bin/bash

set -eo pipefail

SCHEME="${SCHEME:-Release}"
DERIVED_DATA_PATH="./build/"
ARCHIVE_PATH="./build/Archives/${SCHEME}.xcarchive"

WORK_DIR=$(pwd)
API_PRIVATE_KEYS_PATH="${WORK_DIR}/${DERIVED_DATA_PATH}/private_keys"
API_KEY_FILE="${API_PRIVATE_KEYS_PATH}/api_key.p8"
rm -rf "${API_PRIVATE_KEYS_PATH}"
mkdir -p "${API_PRIVATE_KEYS_PATH}"
echo -n "${ENV_API_PRIVATE_KEY_BASE64}" | base64 --decode > "${API_KEY_FILE}"

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
    -derivedDataPath "${DERIVED_DATA_PATH}" \
    -authenticationKeyPath "${API_KEY_FILE}" \
    -authenticationKeyID "${ENV_API_KEY_ID}" \
    -authenticationKeyIssuerID "${ENV_ISSUER_ID}" \
    -allowProvisioningUpdates

# Archive app
xcrun xcodebuild archive \
    -workspace Mastodon.xcworkspace \
    -scheme Mastodon \
    -configuration "${SCHEME}" \
    -destination "generic/platform=iOS" \
    -parallelizeTargets \
    -showBuildTimingSummary \
    -derivedDataPath "${DERIVED_DATA_PATH}"\
    -archivePath "${ARCHIVE_PATH}" \
    -authenticationKeyPath "${API_KEY_FILE}" \
    -authenticationKeyID "${ENV_API_KEY_ID}" \
    -authenticationKeyIssuerID "${ENV_ISSUER_ID}" \
    -allowProvisioningUpdates

# Copy Linkmap files
mkdir "./build/Archives/${SCHEME}.xcarchive/Linkmaps"
find ./build -iname *-LinkMap-*.txt -exec cp "{}" "./build/Archives/${SCHEME}.xcarchive/Linkmaps/"  \;

# Copy Performance test files
mkdir "./build/Archives/${SCHEME}.xcarchive/EmergePerfTests"
cp -R "./build/Build/Products/Release-iphoneos/MastodonUITests-Runner.app/PlugIns/MastodonUITests.xctest" "./build/Archives/${SCHEME}.xcarchive/EmergePerfTests/"

# Create Performance Test Setup
TEST_CASES_FILE="./build/Archives/${SCHEME}.xcarchive/EmergePerfTests/info.yaml"
touch "${TEST_CASES_FILE}"
TEST_PLAN="testClasses:"
TEST_PLAN="${TEST_PLAN}\n  - class: MastodonPerformanceTest"
TEST_PLAN="${TEST_PLAN}\n    spans:"
TEST_PLAN="${TEST_PLAN}\n      - didFinishLaunching"
echo -e $TEST_PLAN > $TEST_CASES_FILE