#!/bin/bash

# Build the Flutter web app and deploys it to the server web folder
set -e  # Exit on any error

echo "🚀 OneUp Web App Deployment Script"
echo "=================================="

# Configuration
FLUTTER_PROJECT_DIR="."
WEB_DIR="../server/web"
BUILD_DIR="./build/web"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

## Clean previous build
#print_status "Cleaning previous build..."
#flutter clean
#
## Get dependencies
#print_status "Getting dependencies..."
#flutter pub get

# Build web app
print_status "Building web app (release mode)..."
flutter build web --release

# Remove old web files
print_status "Removing old web files..."
rm -rf "$WEB_DIR"/*

# Copy new build files
print_status "Copying new build files..."
cp -r "$BUILD_DIR"/* "$WEB_DIR/"

print_status "Web app deployed successfully!"
print_status "Server web directory: $WEB_DIR"
print_status "Files copied:"
ls -la "$WEB_DIR"

echo ""
print_status "Next steps:"
echo "1. Restart your Rust server: cargo run"
echo "2. Access your app at: http://localhost:8080/"
echo "3. Test API endpoints at: http://localhost:8080/api/health"
