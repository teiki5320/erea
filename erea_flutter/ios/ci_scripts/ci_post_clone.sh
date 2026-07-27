#!/bin/sh
# Script exécuté par Xcode Cloud juste après le clone du dépôt.
# Xcode Cloud ne connaît pas Flutter : il faut installer le SDK, générer
# ios/Flutter/Generated.xcconfig (via `flutter pub get`) et installer les
# Pods avant que `xcodebuild archive` ne se lance.
set -e

git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

flutter precache --ios

cd "$CI_PRIMARY_REPOSITORY_PATH/erea_flutter"
flutter pub get

# Écrit toute la configuration Xcode du mode Release (Generated.xcconfig
# complet, flutter_export_environment.sh) sans compiler : l'archive de
# Xcode Cloud échoue en quelques secondes si cette étape manque.
flutter build ios --release --config-only --no-codesign

if ! command -v pod >/dev/null 2>&1; then
  HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods
fi
cd ios
pod install
