#!/bin/bash

# Checks that Core Data files other than the current one are not modified
# in a pull request.
CORE_DATA_PATH="MastodonSDK/Sources/CoreDataStack/CoreData.xcdatamodeld"
CURRENT_CORE_DATA_FILE="$(plutil -extract _XCCurrentVersionName raw "$CORE_DATA_PATH"/.xccurrentversion)"

echo "::group::Fetch origin/develop branch"
git fetch --progress --depth=1 origin develop &
wait
echo "::endgroup::"

echo
echo "Current Core Data version: $CURRENT_CORE_DATA_FILE"
git diff --compact-summary --exit-code origin/develop -- $CORE_DATA_PATH ":!$CORE_DATA_PATH/$CURRENT_CORE_DATA_FILE"

if [ $? -eq 0 ]; then
	echo "Core Data files are not modified."
else
	echo
	echo "::error::Core Data models (.xcdatamodel) older than the current version are modified."
	echo "Please revert them to their original state, and make sure your changes are applied only to the most recent version."
	echo "::notice::This may be caused by new Core Data model versions having recently been added to the project."
	exit 1
fi
