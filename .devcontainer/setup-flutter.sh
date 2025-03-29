#!/bin/bash
set -e

# Install required dependencies
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  curl \
  git \
  unzip \
  xz-utils \
  zip \
  libglu1-mesa \
  cmake \
  ninja-build \
  pkg-config \
  libgtk-3-dev \
  liblzma-dev

# Create a directory for Flutter
mkdir -p /home/vscode/flutter
cd /home/vscode/flutter

# Download Flutter
FLUTTER_VERSION="3.19.3"
curl -o flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_$FLUTTER_VERSION-stable.tar.xz
tar xf flutter.tar.xz
rm flutter.tar.xz

# Add Flutter to PATH
echo 'export PATH="$PATH:/home/vscode/flutter/flutter/bin"' >> ~/.bashrc
echo 'export PATH="$PATH:/home/vscode/flutter/flutter/bin"' >> ~/.zshrc

# Make the flutter command available in the current terminal session
export PATH="$PATH:/home/vscode/flutter/flutter/bin"

# Run basic Flutter commands to set up
flutter config --no-analytics
flutter precache
flutter doctor

# Create a simple Flutter project only if we're not in the .codespaces directory
WORKSPACE_DIR="/workspaces/$(ls -A /workspaces | head -1)"
WORKSPACE_NAME=$(basename "$WORKSPACE_DIR")

if [ ! -f "$WORKSPACE_DIR/pubspec.yaml" ]; then
  cd "$WORKSPACE_DIR"
  
  # Create a temporary project with a valid name
  PROJECT_NAME="flutter_app"
  
  # Create the project with a proper name
  flutter create --project-name=$PROJECT_NAME .
  
  echo "Flutter project created as $PROJECT_NAME"
fi

echo "Flutter setup completed!"