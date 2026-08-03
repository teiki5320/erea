/// Région du joueur, SANS géolocalisation : on lit simplement le pays de
/// réglage de l'appareil (celui d'iOS/Android), disponible hors ligne et
/// sans aucune permission. Un iPhone configuré « Sénégal » donne `SN`.
///
/// Usage actuel : un joueur détecté en Afrique voit son mode Classique
/// « Tout » mélanger l'univers Afrique et le reste du monde — l'app
/// n'est plus écrite uniquement pour un joueur français. Le défi du
/// jour, lui, reste mondial et identique pour tous.
library;


import 'package:flutter/foundation.dart';

/// Codes ISO 3166-1 des pays d'Afrique.
const Set<String> _paysAfricains = {
  'DZ', 'AO', 'BJ', 'BW', 'BF', 'BI', 'CV', 'CM', 'CF', 'TD', 'KM', 'CG',
  'CD', 'CI', 'DJ', 'EG', 'GQ', 'ER', 'SZ', 'ET', 'GA', 'GM', 'GH', 'GN',
  'GW', 'KE', 'LS', 'LR', 'LY', 'MG', 'MW', 'ML', 'MR', 'MU', 'MA', 'MZ',
  'NA', 'NE', 'NG', 'RW', 'ST', 'SN', 'SC', 'SL', 'SO', 'ZA', 'SS', 'SD',
  'TZ', 'TG', 'TN', 'UG', 'ZM', 'ZW',
};

/// Pays CHOISI par le joueur dans le parcours d'accueil (code ISO), posé
/// au démarrage depuis le Store puis mis à jour par l'écran de choix.
/// Prioritaire sur le réglage de l'appareil : un choix explicite vaut
/// toujours mieux qu'une déduction.
String? paysChoisiIso;

/// Forçage pour les tests : court-circuite la lecture de l'appareil.
@visibleForTesting
String? regionForcee;

/// Pays du RÉGLAGE de l'appareil, sans tenir compte du choix du joueur.
/// Sert au bouton « Détecter mon pays » et à la présélection de l'accueil.
String? codePaysAppareil() =>
    regionForcee ?? PlatformDispatcher.instance.locale.countryCode;

String? _codePays() => regionForcee ?? paysChoisiIso ?? codePaysAppareil();

/// Le joueur est-il en Afrique (pays choisi, sinon réglage de l'appareil) ?
bool get joueurEnAfrique {
  final code = _codePays();
  return code != null && _paysAfricains.contains(code.toUpperCase());
}
