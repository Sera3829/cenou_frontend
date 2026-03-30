#!/bin/bash

# Installer Flutter
git clone https://github.com/flutter/flutter.git --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

# Vérifier installation
flutter doctor

# Installer dépendances
flutter pub get

# Build web
flutter build web