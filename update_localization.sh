#!/bin/zsh

set -ev

SRCROOT=`pwd`
PODS_ROOT='Pods'

echo ${SRCROOT}

# Task 1
# here we use the template source as input to
# generate strings so we could use new strings 
# before sync to Crowdin

# clean Base.lproj
rm -rf ${SRCROOT}/Localization/StringsConvertor/input/Base.lproj
# copy tempate sources
mkdir ${SRCROOT}/Localization/StringsConvertor/input/Base.lproj
cp ${SRCROOT}/Localization/app.json ${SRCROOT}/Localization/StringsConvertor/input/Base.lproj/app.json
cp ${SRCROOT}/Localization/ios-infoPlist.json ${SRCROOT}/Localization/StringsConvertor/input/Base.lproj/ios-infoPlist.json
cp ${SRCROOT}/Localization/Localizable.stringsdict ${SRCROOT}/Localization/StringsConvertor/input/Base.lproj/Localizable.stringsdict

# Task 2 generate strings file
cd ${SRCROOT}/Localization/StringsConvertor
sh ./scripts/build.sh

# Task 3 copy strings file
cp -R ${SRCROOT}/Localization/StringsConvertor/output/main/ ${SRCROOT}/Mastodon/Resources
cp -R ${SRCROOT}/Localization/StringsConvertor/output/module/ ${SRCROOT}/MastodonSDK/Sources/MastodonLocalization/Resources
cp -R ${SRCROOT}/Localization/StringsConvertor/Intents/output/ ${SRCROOT}/MastodonIntent

# Task 4 swiftgen
cd ${SRCROOT}
echo "${PODS_ROOT}/SwiftGen/bin/swiftgen"
if [[ -f "${PODS_ROOT}/SwiftGen/bin/swiftgen" ]] then 
   "${PODS_ROOT}/SwiftGen/bin/swiftgen"
else
	echo "Run 'bundle exec pod install' or update your CocoaPods installation."
fi

# Task 5 clean temp file
rm -rf ${SRCROOT}/Localization/StringsConvertor/output
rm -rf ${SRCROOT}/Localization/StringsConvertor/intents/output
