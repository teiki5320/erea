import 'package:flutter/widgets.dart';

/// « Réduire les animations » (iOS : Réglages → Accessibilité → Mouvement),
/// lu à la SOURCE.
///
/// Pourquoi pas `MediaQuery.of(context).disableAnimations` ? Parce que le
/// widget MediaQuery est lui-même un observateur du binding et n'est
/// reconstruit qu'à la phase de build. Toute lecture faite AVANT cette
/// phase — callback d'animation, écouteur de ticker, callback de geste,
/// `didChangeAccessibilityFeatures` — obtient la valeur de la frame
/// précédente. C'est exactement ainsi que le réglage se retrouvait ignoré
/// pendant une frame après avoir été activé.
///
/// Règle : dans `build()`, MediaQuery convient (et propage la
/// reconstruction). PARTOUT ailleurs, utiliser ceci.
bool get animationsReduites => WidgetsBinding
    .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
