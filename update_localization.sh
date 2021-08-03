#!/bin/zsh

SRCROOT=`pwd`
PODS_ROOT='Pods'

echo ${SRCROOT}
# task1 generate strings file
cd ${SRCROOT}/Localization/StringsConvertor
sh ./scripts/build.sh

# task2 copy strings file /Localization/StringsConvertor/output to /Mastodon/Resources

cp -r ${SRCROOT}/Localization/StringsConvertor/output/  ${SRCROOT}/Mastodon/Resources/

# task3 swiftgen
cd ${SRCROOT}
echo "${PODS_ROOT}/SwiftGen/bin/swiftgen"
if [[ -f "${PODS_ROOT}/SwiftGen/bin/swiftgen" ]] then 
   "${PODS_ROOT}/SwiftGen/bin/swiftgen"
else
	echo "Run 'pod install' or update your CocoaPods installation."
fi

#task4 clean temp file
rm -rf ${SRCROOT}/Localization/StringsConvertor/output
