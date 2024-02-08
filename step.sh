#!/usr/bin/env bash
# Fail if any commands fail
set -e

# Define constants
buildNoOption="--build-no"
buildNoOptionAbbr="-b"
majorFlag="--major"
majorFlagAbbr="-M"
minorFlag="--minor"
minorFlagAbbr="-m"
patchFlag="--patch"
patchFlagAbbr="-p"
versionTag="version: "
buildNoSplitter="+"
versionNoSplitter="."

# Determine version type
if [[ -n "$BITRISE_VERSION_TYPE" ]]; then
    VERSION_TYPE="$BITRISE_VERSION_TYPE"
elif echo "$BITRISE_TRIGGERED_WORKFLOW_ID" | grep -iqF "major"; then
    VERSION_TYPE="major"
elif echo "$BITRISE_TRIGGERED_WORKFLOW_ID" | grep -iqF "minor"; then
    VERSION_TYPE="minor"
else
    VERSION_TYPE="patch"
fi

echo -e '\nUpdating '$VERSION_TYPE' version...\n'

# Define functions
# VersionManager function
versionManager() {
    local newBuildNo="$1"
    local majorVer="$2"
    local minorVer="$3"
    local patchVer="$4"

    # Declare and assign separately to avoid masking return values
    local pubspecFilePath
    pubspecFilePath="$(pwd)/pubspec.yaml"

    # Check if pubspec file exists
    if [[ ! -f $pubspecFilePath ]]; then
        echo "Error: pubspec file does not exist."
        exit 1
    fi

    # Construct new version number
    local newVersionNo
    versionInfo=$(grep -E "^$versionTag" "$pubspecFilePath" | head -n 1)


    # Check if version info exists
    if [[ -z $versionInfo ]]; then
        echo "Error: No version info in pubspec.yaml."
        exit 1
    fi

    # Extract version number
    local versionNo
    versionNo=$(echo "${versionInfo[0]}" | sed "s/$versionTag//;s/$buildNoSplitter.*//")

    # Check if version number is correct
    if ! [[ $versionNo =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Version info in pubspec.yaml is incorrect."
        exit 1
    fi

    # Split version number
    IFS='.' read -r -a versions <<< "$versionNo"

    # Determine new version based on flags
    local newVersions
    if [[ $majorVer -eq 1 ]]; then
        newVersions=($(increaseMajorVersion "${versions[@]}"))
    elif [[ $minorVer -eq 1 ]]; then
        newVersions=($(increaseMinorVersion "${versions[@]}"))
    else
        newVersions=($(increasePatchVersion "${versions[@]}"))
    fi

    # Check if new version is obtained
    if [[ ${#newVersions[@]} -eq 0 ]]; then
        echo "Error: Getting new version failed"
        exit 1
    fi

    # Construct new version number
    local newVersionNo
    newVersionNo=$(IFS=".$versionNoSplitter"; echo "${newVersions[*]}")

    # Construct new version info
    local newVersionInfo="$versionTag$newVersionNo"
    if [[ ! -z $newBuildNo ]]; then
        newVersionInfo="$newVersionInfo$buildNoSplitter$newBuildNo"
    fi

    # Update pubspec.yaml
    local escaped_newVersionInfo
    escaped_newVersionInfo=$(printf '%s\n' "$newVersionInfo" | sed -e 's/[\/&]/\\&/g')
    sed -i '' "s/^$versionTag.*/$escaped_newVersionInfo/" "$pubspecFilePath"

    echo "$newVersionNo"
}

# Increase major version function
increaseMajorVersion() {
    local majorVersion="$1"
    local minorVersion="$2"
    local patchVersion="$3"

    # Declare and assign separately to avoid masking return values
    local newMajorVersion=$((majorVersion + 1))
    local newMinorVersion=0
    local newPatchVersion=0

    echo "$newMajorVersion" "$newMinorVersion" "$newPatchVersion"
}

# Increase minor version function
increaseMinorVersion() {
    local majorVersion="$1"
    local minorVersion="$2"
    local patchVersion="$3"

    # Declare and assign separately to avoid masking return values
    local newMajorVersion="$majorVersion"
    local newMinorVersion=$((minorVersion + 1))
    local newPatchVersion=0

    echo "$newMajorVersion" "$newMinorVersion" "$newPatchVersion"
}

# Increase patch version function
increasePatchVersion() {
    local majorVersion="$1"
    local minorVersion="$2"
    local patchVersion="$3"

    # Declare and assign separately to avoid masking return values
    local newMajorVersion="$majorVersion"
    local newMinorVersion="$minorVersion"
    local newPatchVersion=$((patchVersion + 1))

    echo "$newMajorVersion" "$newMinorVersion" "$newPatchVersion"
}

# Start of the script

cd "$BITRISE_FLUTTER_PROJECT_LOCATION"

echo -e '\nUpdating '$VERSION_TYPE' version...\n'

# Parse arguments
newBuildNo="$BITRISE_BUILD_NUMBER"
majorVerFlag=0
minorVerFlag=0
patchVerFlag=0

# Set flags based on version type
case "$VERSION_TYPE" in
    "major")
        majorVerFlag=1
        ;;
    "minor")
        minorVerFlag=1
        ;;
    "patch")
        patchVerFlag=1
        ;;
esac

# Call VersionManager with parsed arguments and build number
VERSION_NO=$(versionManager "$newBuildNo" "$majorVerFlag" "$minorVerFlag" "$patchVerFlag") || { echo "Error occurred while getting version number: $VERSION_NO"; exit 1; }

echo -e 'Version No.: '$VERSION_NO'\n'
echo -e 'Build number: '$BITRISE_BUILD_NUMBER'\n'

echo -e 'Updating pubspec.yaml...\n'

# Commit changes if enabled
echo -e 'Updating pubspec.yaml...\n'

# Assign default value to commit_version_changes if not provided
if [[ -z "$commit_version_changes" ]]; then
    commit_version_changes="true"
fi

# Create a branch for the changes
git checkout -b "Release/$VERSION_NO"

# Commit changes if enabled
if [[ "$commit_version_changes" == "true" ]]; then
    # Set default commit message if not provided
    if [[ -z "$commit_message" ]]; then
        commit_message="Bumped $VERSION_TYPE version"
    fi

    # Set default commit author if not provided
    if [[ -z "$commit_author_name" ]]; then
        commit_author_name="Bitrise Buildbot"
    fi

    if [[ -z "$commit_author_email" ]]; then
        commit_author_email="<PROD_AppDeveloper@healy.world>"
    fi

    git commit -am "$commit_message" --author="$commit_author_name $commit_author_email"

    echo -e '\nPushing the branch and creating a version tag...\n'
    git push -u origin "Release/$VERSION_NO"

    echo -e '\nPushing a version tag...\n'
    git tag "$VERSION_NO"
    git push -u origin "$VERSION_NO"

    echo -e '\nUpdated '$VERSION_TYPE' version...\n'
else
    echo -e 'Changes not committed.\n'
fi

