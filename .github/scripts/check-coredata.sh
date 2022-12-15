# Checks that Core Data files other than the current one are not modified
# in a pull request.
CORE_DATA_PATH="MastodonSDK/Sources/CoreDataStack/CoreData.xcdatamodeld"
CURRENT_CORE_DATA_FILE="$(plutil -extract _XCCurrentVersionName raw "$CORE_DATA_PATH"/.xccurrentversion)"

echo "Current Core Data version: $CURRENT_CORE_DATA_FILE"
git diff --compact-summary --exit-code origin/develop -- $CORE_DATA_PATH ":!$CORE_DATA_PATH/$CURRENT_CORE_DATA_FILE"

if [ $? -eq 0 ]; then
	echo "Core Data files are not modified."
else
	echo
	echo "\033[31mERROR! Core Data files other than the current one are modified. Please revert them to their original state:\033[0m"
	echo "    \033[90m$\033[0m git diff --name-only origin/develop -- $CORE_DATA_PATH"
	exit 1
fi
