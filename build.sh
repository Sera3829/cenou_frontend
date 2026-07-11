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

# Build web (release)
flutter build web --release
