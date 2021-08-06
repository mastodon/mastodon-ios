#!/bin/zsh

set -ev

SRCROOT=`pwd`
PODS_ROOT='Pods'

echo ${SRCROOT}

# task 1 generate strings file
cd ${SRCROOT}/Localization/StringsConvertor
sh ./scripts/build.sh

# task 2 copy strings file
cp -R ${SRCROOT}/Localization/StringsConvertor/output/ ${SRCROOT}/Mastodon/Resources
cp -R ${SRCROOT}/Localization/StringsConvertor/Intents/output/ ${SRCROOT}/MastodonIntent

# task 3 swiftgen
cd ${SRCROOT}
echo "${PODS_ROOT}/SwiftGen/bin/swiftgen"
if [[ -f "${PODS_ROOT}/SwiftGen/bin/swiftgen" ]] then 
   "${PODS_ROOT}/SwiftGen/bin/swiftgen"
else
	echo "Run 'pod install' or update your CocoaPods installation."
fi

#task 4 clean temp file
rm -rf ${SRCROOT}/Localization/StringsConvertor/output
rm -rf ${SRCROOT}/Localization/StringsConvertor/intents/output
