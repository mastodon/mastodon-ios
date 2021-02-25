#!/bin/zsh

SRCROOT=`pwd`
echo ${SRCROOT}
# task1 generate strings file
cd ${SRCROOT}/Localization/StringsConvertor
sh ./scripts/build.sh

# task2 copy strings file /Localization/StringsConvertor/output to /Mastodon/Resources

cp -r ${SRCROOT}/Localization/StringsConvertor/output/  ${SRCROOT}/Mastodon/Resources/

# task3 swiftgen
cd ${SRCROOT}

if command -v swiftgen >/dev/null 2>&1; then 
   swiftgen
else
	echo "please install swiftgen by run brew install swiftgen"
fi

#task4 clean temp file
rm -rf ${SRCROOT}/Localization/StringsConvertor/output
rm -rf ${SRCROOT}/Localization/StringsConvertor/intput
