#!/bin/bash
set -e

# Installer Flutter — IMPORTANT : branche stable épinglée.
# (Avant : clone de master → n'importe quelle version instable de Flutter
# pouvait casser le build Vercel du jour au lendemain.)
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi
export PATH="$PATH:$(pwd)/flutter/bin"

flutter --version

# Installer dépendances
flutter pub get

# Métadonnées de version injectées dans le build (voir lib/config/app_version.dart).
# La date reflète ce build ; le commit et la version viennent du dépôt.
BUILD_DATE=$(date -u +%Y-%m-%d)
GIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "")
APP_VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: *//' | cut -d'+' -f1)

# Build web (release)
flutter build web --release \
  --dart-define=BUILD_DATE="$BUILD_DATE" \
  --dart-define=GIT_SHA="$GIT_SHA" \
  --dart-define=APP_VERSION="$APP_VERSION"
