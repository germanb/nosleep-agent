#!/bin/bash

set -e

echo "Building NoSleepAgent.app..."

# Build the executable
swift build -c release

# Create app bundle structure
APP_DIR="NoSleepAgent.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy executable
cp .build/release/NoSleepAgent "$APP_DIR/Contents/MacOS/"

# Copy Info.plist
cp NoSleepAgent/Info.plist "$APP_DIR/Contents/"

echo "✓ NoSleepAgent.app created successfully"
echo "  To run: open NoSleepAgent.app"
