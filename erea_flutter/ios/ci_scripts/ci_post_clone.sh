#!/bin/sh
# Script exécuté par Xcode Cloud juste après le clone du dépôt.
#
# Xcode Cloud ne connaît pas Flutter : il faut installer le SDK, générer
# ios/Flutter/Generated.xcconfig (via `flutter pub get`) et installer les
# Pods avant que `xcodebuild archive` ne se lance.
#
# Le projet Flutter n'est pas à la racine du dépôt : il vit dans
# `erea_flutter/`. Tous les `cd` partent donc de $CI_PRIMARY_REPOSITORY_PATH.
set -e

FLUTTER_DIR="$HOME/flutter"
PROJECT_DIR="$CI_PRIMARY_REPOSITORY_PATH/erea_flutter"

echo "🦋 Xcode Cloud — préparation Flutter"
echo "ℹ️  HOME                       = $HOME"
echo "ℹ️  CI_PRIMARY_REPOSITORY_PATH = $CI_PRIMARY_REPOSITORY_PATH"
echo "ℹ️  PROJECT_DIR                = $PROJECT_DIR"
xcodebuild -version

# Clone du SDK, idempotent : les runners Xcode Cloud peuvent être réutilisés.
if [ ! -d "$FLUTTER_DIR" ]; then
  echo "📥 Installation de Flutter stable dans $FLUTTER_DIR"
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_DIR"
else
  echo "♻️  Flutter déjà présent dans $FLUTTER_DIR"
fi

# Préfixe (et non suffixe) : on veut ce SDK-là, pas un flutter système.
export PATH="$FLUTTER_DIR/bin:$PATH"
flutter --version

# Le projet Xcode committé est intégré via CocoaPods. Sur les stables
# récentes, Flutter active Swift Package Manager par défaut : podhelper
# saute alors les plugins compatibles SwiftPM (shared_preferences_foundation
# n'est plus installé par pod install) et l'archive échoue avec
# « Module 'shared_preferences_foundation' not found ». On force le mode
# CocoaPods, celui du projet.
flutter config --no-enable-swift-package-manager || true

echo "📦 flutter precache --ios"
flutter precache --ios

cd "$PROJECT_DIR"

echo "📦 flutter pub get"
flutter pub get

# Écrit toute la configuration Xcode du mode Release (Generated.xcconfig
# complet, flutter_export_environment.sh) sans compiler : l'archive de
# Xcode Cloud échoue en quelques secondes (exit 65) si cette étape manque.
echo "📦 flutter build ios --config-only"
flutter build ios --release --config-only --no-codesign

# Garde-fou : sans Generated.xcconfig, le Podfile lève une exception et les
# phases de build « Run Script » / « Thin Binary » de Runner échouent avec
# un exit 65 peu bavard. Autant échouer ici, où le log est lisible.
GENERATED="$PROJECT_DIR/ios/Flutter/Generated.xcconfig"
if [ ! -f "$GENERATED" ]; then
  echo "❌ $GENERATED absent après flutter pub get" >&2
  exit 1
fi
echo "✅ Generated.xcconfig produit :"
cat "$GENERATED"

echo "📦 pod install"
if ! command -v pod >/dev/null 2>&1; then
  HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods
fi
cd ios
pod --version
pod install --repo-update

echo "✅ Préparation terminée"
