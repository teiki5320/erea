import 'package:flutter/material.dart' hide Badge;

import '../data/events_repository.dart';
import '../game/badges.dart';

/// Les icônes dessinées d'Erea (`assets/img/icones/`), à la place des
/// emoji de l'interface : les emoji du système faisaient « générique »,
/// et changeaient d'allure d'un téléphone à l'autre.
///
/// Les données gardent leurs emoji (titres de niveau, succès, catégories,
/// difficultés) : seul l'affichage passe par ici. Un emoji sans icône —
/// ceux des 1 830 événements, les drapeaux — reste affiché tel quel.
/// Le texte partagé et les notifications gardent aussi leurs emoji : ce
/// sont des caractères, pas des images.
const Map<String, String> _parEmoji = {
  '🗓️': 'defi',
  '🎯': 'classique',
  '⏱️': 'chrono',
  '⏱': 'chrono',
  '🎡': 'roulette',
  '🚀': 'packs',
  '🔥': 'serie',
  '⚔️': 'pouvoir',
  '🔬': 'sciences',
  '🎭': 'arts',
  '⚽': 'quotidien',
  '🌍': 'tout',
  '🏺': 'pack_egypte',
  '🏯': 'pack_asie',
  '🌎': 'pack_ameriques',
  '💡': 'ampoule',
  '🏆': 'trophee',
  '🔒': 'cadenas',
  '⏳': 'sablier',
  '📚': 'livres',
  '🐣': 'poussin',
  '🔍': 'loupe',
  '🧭': 'boussole',
  '🗺️': 'carte',
  '🦉': 'chouette',
  '👑': 'couronne',
  '🌟': 'etoile',
  '🎓': 'toque',
  '🗄️': 'archives',
  '🔮': 'boule_cristal',
  '⏰': 'reveil',
  '💎': 'diamant',
  '👣': 'pas',
  '🎪': 'triple',
  '💫': 'etoile_filante',
  '🎨': 'palette',
  '🔁': 'boucle',
  '🏛️': 'temple',
  '📅': 'trois_jours',
  '⚡': 'eclair',
  '😌': 'facile',
  '🙂': 'normal',
  '👆': 'doigt',
  '✅': 'valide',
  '📤': 'partager',
  '⏸': 'pause',
  '🏁': 'arrivee',
  '🌐': 'globe_auto',
  '💛': 'coeur',
};

/// L'icône d'un emoji de l'interface, ou l'emoji lui-même s'il n'en a pas.
Widget icone(String emoji, {double taille = 24}) {
  final nom = _parEmoji[emoji];
  if (nom == null) {
    return Text(emoji, style: TextStyle(fontSize: taille * 0.85));
  }
  return iconeNommee(nom, taille: taille);
}

/// Une icône par son nom de fichier.
Widget iconeNommee(String nom, {double taille = 24}) => Image.asset(
      'assets/img/icones/$nom.webp',
      width: taille,
      height: taille,
      filterQuality: FilterQuality.medium,
      // Une icône décrit ce que dit déjà le texte voisin.
      excludeFromSemantics: true,
    );

/// Catégories et packs : la clé départage les emoji partagés (🌍 sert à
/// « Tout » comme au pack Afrique).
Widget iconeJouable(Playable p, {double taille = 24}) => p.key == 'pack:afrique'
    ? iconeNommee('pack_afrique', taille: taille)
    : icone(p.emoji, taille: taille);

/// Succès : « Une semaine » partage son 🗓️ avec le Défi du jour.
Widget iconeBadge(Badge b, {double taille = 24}) => b.cle == 'serie-7'
    ? iconeNommee('semaine', taille: taille)
    : icone(b.emoji, taille: taille);
