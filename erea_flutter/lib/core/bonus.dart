/// Bonus gagnés en montant de niveau (1.0.8) : les règles, sans écran.
///
/// Le principe tient en trois lignes, décidées avec Jean le 31 octobre
/// 2026 : un bonus se DÉCOUVRE à un niveau précis (un exemplaire offert),
/// les découvertes sont espacées de quatre niveaux pour qu'aucune n'arrive
/// trop tôt, et le stock reste petit — sans quoi le jeu deviendrait facile.
library;

import 'dart:math' as math;

import 'timeline_scale.dart';

enum BonusType {
  remplacer(
    niveau: 5,
    nom: 'Remplacer',
    icone: 'boucle',
    effet: 'Change la question pour une autre',
  ),
  epoque(
    niveau: 9,
    nom: 'Époque',
    icone: 'temple',
    effet: 'Montre l’époque de la bonne date',
  ),
  repere(
    niveau: 13,
    nom: 'Repère',
    icone: 'carte',
    effet: 'Pose un événement daté sur la frise',
  ),
  zoom(
    niveau: 17,
    nom: 'Zoom',
    icone: 'loupe',
    effet: 'Resserre la frise sur 500 ans',
  ),
  secondeChance(
    niveau: 21,
    nom: 'Seconde chance',
    icone: 'coeur',
    effet: 'Trop loin ? « Plus tôt » ou « plus tard », et tu rejoues',
  ),
  xpDouble(
    niveau: 25,
    nom: 'XP double',
    icone: 'eclair',
    effet: 'Les manches suivantes rapportent deux fois plus d’XP',
  );

  const BonusType({
    required this.niveau,
    required this.nom,
    required this.icone,
    required this.effet,
  });

  /// Niveau de découverte : un exemplaire offert en l'atteignant.
  final int niveau;
  final String nom;

  /// Nom de fichier de `assets/img/icones/`.
  final String icone;
  final String effet;

  /// Les bonus qui changent le SCORE. Une partie qui en a vu jouer un est
  /// « aidée » : hors records, hors classements. L'XP double, lui, ne
  /// touche que l'XP.
  bool get aide => this != BonusType.xpDouble;
}

/// Exemplaires gardés au plus de chaque bonus : le stock d'un joueur qui
/// ne s'en sert jamais ne grossit pas indéfiniment.
const int stockMax = 2;

/// Un bonus par partie, pas plus.
const int bonusParPartie = 1;

/// Niveaux de titre qui offrent un XP double une fois celui-ci découvert.
const List<int> niveauxXpDouble = [30, 40, 50];

/// Le bonus découvert à [niveau], s'il y en a un.
BonusType? decouverteA(int niveau) {
  for (final b in BonusType.values) {
    if (b.niveau == niveau) return b;
  }
  return null;
}

/// Un bonus est découvert dès que son niveau est atteint : c'est une
/// conséquence du niveau, rien à stocker.
bool estDecouvert(BonusType b, int niveau) => niveau >= b.niveau;

/// Les bonus qu'un joueur peut CHOISIR : découverts, hors XP double (qui
/// reste la récompense des grands niveaux).
List<BonusType> choisissables(int niveau) => [
      for (final b in BonusType.values)
        if (b != BonusType.xpDouble && estDecouvert(b, niveau)) b,
    ];

/// Ce qu'apporte le passage de [avant] à [apres].
class Recompenses {
  const Recompenses({
    this.decouvertes = const [],
    this.choix = 0,
    this.xpDouble = 0,
  });

  /// Bonus découverts, un exemplaire chacun.
  final List<BonusType> decouvertes;

  /// Bonus à choisir parmi les découverts.
  final int choix;

  /// XP double offerts par un nouveau titre (30, 40, 50).
  final int xpDouble;

  bool get vide => decouvertes.isEmpty && choix == 0 && xpDouble == 0;
}

/// Un bonus tous les deux niveaux à partir du 5 : les niveaux impairs.
/// Une découverte tous les quatre (5, 9, 13, 17, 21, 25) ; les autres
/// impairs (7, 11, 15…) laissent CHOISIR un bonus déjà découvert.
Recompenses recompensesEntre(int avant, int apres) {
  final decouvertes = <BonusType>[];
  var choix = 0;
  var xpDouble = 0;
  for (var n = avant + 1; n <= apres; n++) {
    final d = decouverteA(n);
    if (d != null) {
      decouvertes.add(d);
    } else if (n > BonusType.remplacer.niveau && n.isOdd) {
      choix++;
    }
    if (niveauxXpDouble.contains(n) && estDecouvert(BonusType.xpDouble, n)) {
      xpDouble++;
    }
  }
  return Recompenses(
      decouvertes: decouvertes, choix: choix, xpDouble: xpDouble);
}

/// Mise à jour vers la 1.0.8 : un joueur déjà avancé reçoit un exemplaire
/// de chaque bonus des niveaux qu'il a déjà passés — les découvertes
/// seulement, pas les choix ni les XP double qu'il aurait pu gagner.
List<BonusType> cadeauxDeBienvenue(int niveau) => [
      for (final b in BonusType.values)
        if (estDecouvert(b, niveau)) b,
    ];

/// Fenêtre du Zoom : 500 ans qui contiennent [annee], placés au hasard
/// pour que la bonne date ne tombe jamais pile au milieu. [r] dans [0, 1[.
({int de, int a}) fenetreZoom(int annee, double r) {
  const largeur = 500;
  // La date reste à 50 ans au moins des bords : sinon la fenêtre la
  // désignait (« entre 1649 et 2149 », c'est 1649).
  var de = annee - 50 - (r * (largeur - 100)).round();
  de = math.max(minYear, math.min(de, maxYear - largeur));
  return (de: de, a: de + largeur);
}

/// Écart toléré entre un Repère et la bonne date : assez près pour aider,
/// assez loin pour ne rien donner.
const int repereEcartMin = 50;
const int repereEcartMax = 300;

/// Au-delà de cet écart, la Seconde chance se déclenche.
const int secondeChanceEcart = 50;
