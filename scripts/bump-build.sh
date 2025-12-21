#!/bin/bash

# Bump build number script for Autophagy
# Run this before archiving to increment the build number

set -e

cd "$(dirname "$0")/.."

PROJECT_FILE="project.yml"

if [ ! -f "$PROJECT_FILE" ]; then
    echo "Error: $PROJECT_FILE not found"
    exit 1
fi

# Get current build number (first occurrence)
CURRENT_BUILD=$(grep -m1 "CURRENT_PROJECT_VERSION:" "$PROJECT_FILE" | sed 's/.*: //')
NEW_BUILD=$((CURRENT_BUILD + 1))

echo "Bumping build number: $CURRENT_BUILD -> $NEW_BUILD"

# Update all CURRENT_PROJECT_VERSION occurrences
sed -i '' "s/CURRENT_PROJECT_VERSION: $CURRENT_BUILD/CURRENT_PROJECT_VERSION: $NEW_BUILD/g" "$PROJECT_FILE"

# Update CFBundleVersion in Info.plist properties
sed -i '' "s/CFBundleVersion: \"$CURRENT_BUILD\"/CFBundleVersion: \"$NEW_BUILD\"/g" "$PROJECT_FILE"

echo "Updated $PROJECT_FILE"

# Regenerate Xcode project if xcodegen is available
if command -v xcodegen &> /dev/null; then
    echo "Regenerating Xcode project..."
    xcodegen generate
    echo "Done!"
else
    echo "Note: xcodegen not found. Run 'xcodegen generate' manually to update the Xcode project."
fi

echo ""
echo "Build number is now: $NEW_BUILD"
