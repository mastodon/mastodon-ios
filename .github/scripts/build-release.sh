#!/usr/bin/env bash

set -xeu
set -o pipefail

function finish() {
  ditto -c -k --sequesterRsrc --keepParent "${RESULT_BUNDLE_PATH}" "${RESULT_BUNDLE_PATH}.zip"
  rm -rf "${RESULT_BUNDLE_PATH}"
}

trap finish EXIT

SDK="${SDK:-iphoneos}"
WORKSPACE="${WORKSPACE:-Mastodon.xcworkspace}"
SCHEME="${SCHEME:-Mastodon}"
CONFIGURATION=${CONFIGURATION:-Release}

BUILD_DIR=${BUILD_DIR:-.build}
ARTIFACT_PATH=${RESULT_PATH:-${BUILD_DIR}/Artifacts}
RESULT_BUNDLE_PATH="${ARTIFACT_PATH}/${SCHEME}.xcresult"
ARCHIVE_PATH=${ARCHIVE_PATH:-${BUILD_DIR}/Archives/${SCHEME}.xcarchive}
DERIVED_DATA_PATH=${DERIVED_DATA_PATH:-${BUILD_DIR}/DerivedData}
EXPORT_OPTIONS_FILE=".github/support/ExportOptions.plist"

WORK_DIR=$(pwd)
API_PRIVATE_KEYS_PATH="${WORK_DIR}/${BUILD_DIR}/private_keys"
API_KEY_FILE="${API_PRIVATE_KEYS_PATH}/api_key.p8"

rm -rf "${RESULT_BUNDLE_PATH}"

rm -rf "${API_PRIVATE_KEYS_PATH}"
mkdir -p "${API_PRIVATE_KEYS_PATH}"
echo -n "${ENV_API_PRIVATE_KEY_BASE64}" | base64 --decode > "${API_KEY_FILE}"

BUILD_NUMBER=$(app-store-connect get-latest-testflight-build-number $ENV_APP_ID --issuer-id $ENV_ISSUER_ID --key-id $ENV_API_KEY_ID --private-key @file:$API_KEY_FILE)
BUILD_NUMBER=$((BUILD_NUMBER+1))
CURRENT_PROJECT_VERSION=${BUILD_NUMBER:-0}

echo "GITHUB_TAG_NAME=build-$CURRENT_PROJECT_VERSION" >> $GITHUB_ENV

agvtool new-version -all $CURRENT_PROJECT_VERSION

xcrun xcodebuild clean \
    -workspace "${WORKSPACE}" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}"

xcrun xcodebuild archive \
    -workspace "${WORKSPACE}" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -destination generic/platform=iOS \
    -sdk "${SDK}" \
    -parallelizeTargets \
    -showBuildTimingSummary \
    -derivedDataPath "${DERIVED_DATA_PATH}" \
    -archivePath "${ARCHIVE_PATH}" \
    -resultBundlePath "${RESULT_BUNDLE_PATH}" \
    -allowProvisioningUpdates \
    -authenticationKeyPath "${API_KEY_FILE}" \
    -authenticationKeyID "${ENV_API_KEY_ID}" \
    -authenticationKeyIssuerID "${ENV_ISSUER_ID}"

xcrun xcodebuild \
    -exportArchive \
    -archivePath "${ARCHIVE_PATH}" \
    -exportOptionsPlist "${EXPORT_OPTIONS_FILE}" \
    -exportPath "${ARTIFACT_PATH}/${SCHEME}.ipa" \
    -allowProvisioningUpdates \
    -authenticationKeyPath "${API_KEY_FILE}" \
    -authenticationKeyID "${ENV_API_KEY_ID}" \
    -authenticationKeyIssuerID "${ENV_ISSUER_ID}"

# Zip up the Xcode Archive into Artifacts folder.
ditto -c -k --sequesterRsrc --keepParent "${ARCHIVE_PATH}" "${ARTIFACT_PATH}/${SCHEME}.xcarchive.zip"