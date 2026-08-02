import 'dart:math' as math;

const int rounds = 10;
const int maxScore = 1000; // par manche (avant multiplicateur)
const int maxTotal = 11000; // 9 manches + manche finale x2

/// Difficulté choisie par le joueur : module la tolérance, l'XP et les repères.
enum Difficulty {
  // Les multiplicateurs d'XP compensent le barème : à niveau de jeu égal,
  // Difficile rapporte MOINS de points que Facile. Sans compensation,
  // 1,3× ne suffisait pas et le mode exigeant rapportait autant que le
  // mode facile — il n'y avait aucune raison de le choisir.
  facile(
    label: 'Facile',
    emoji: '😌',
    tolMult: 2.2,
    xpMult: 0.75,
    desc: 'Grande marge d’erreur et événements connus — parfait pour débuter !',
  ),
  normal(
    label: 'Normal',
    emoji: '🙂',
    tolMult: 1.0,
    xpMult: 1.0,
    desc: 'L’équilibre classique : marge normale, événements variés.',
  ),
  difficile(
    label: 'Difficile',
    emoji: '🔥',
    tolMult: 0.55,
    xpMult: 1.75,
    desc: 'Marge réduite, événements pointus… mais +75 % d’XP !',
  );

  const Difficulty({
    required this.label,
    required this.emoji,
    required this.tolMult,
    required this.xpMult,
    required this.desc,
  });

  final String label;
  final String emoji;
  final double tolMult;
  final double xpMult;

  /// Montré au joueur dans le sélecteur : ne doit promettre que ce que le
  /// jeu fait réellement (les repères emoji du prototype web ne sont pas
  /// portés — ne pas réintroduire « repères affichés » / « frise nue »).
  final String desc;
}

/// Marge d'erreur de base, en années. Identique à TOUTES les époques.
///
/// Elle a d'abord valu 5 % de l'ancienneté du fait, bornée entre 12 et
/// 90 ans. L'intention était bonne — placer les pyramides à 150 ans près
/// n'est pas une faute grossière — mais la conséquence ne l'était pas :
/// à connaissance ÉGALE, l'Antiquité rapportait bien plus de points. Un
/// fait situé à 50 ans près valait 777 points avant notre ère et 150
/// points en l'an 2000. Une partie qui tirait beaucoup d'Antiquité était
/// donc mécaniquement plus généreuse, et l'écart mesuré entre une partie
/// chanceuse et une partie ingrate atteignait 1,93×.
///
/// La marge est maintenant la même partout : le score ne dépend plus que
/// de ce que le joueur sait, jamais de l'époque tirée.
///
/// La valeur elle-même est un curseur de confort, réglable ici et nulle
/// part ailleurs. À 30 ans, se tromper d'une génération reste une bonne
/// réponse : en Facile il faut situer l'année à ± 24 ans pour les 700
/// points du « vert », à ± 11 ans en Normal, à ± 6 ans en Difficile.
///
/// Elle a valu 12 un temps. C'était jouable sur le récent, mais cela
/// condamnait tout ce qui n'a pas de date au demi-siècle près — soit une
/// grande part de l'Antiquité et de l'archéologie.
const double toleranceBase = 30;

/// Tolérance du barème : [toleranceBase] × le multiplicateur du mode.
///
/// C'est ici, et seulement ici, que la difficulté se joue : Facile ×2,2,
/// Normal ×1, Difficile ×0,55.
double tolerance(Difficulty diff) => toleranceBase * diff.tolMult;

/// Points d'une manche (hors multiplicateur de manche finale).
///
/// `points = round(1000 × exp(−écart / tolérance))`.
///
/// Il n'y a plus de fenêtre explicite à zéro : l'exponentielle y arrive
/// d'elle-même, à 7,6 × la tolérance, soit 201 ans en Facile, 92 en
/// Normal et 51 en Difficile. L'ancienne borne dure (200 ans × mode)
/// était calculée pour une tolérance qui montait jusqu'à 90 ans sur
/// l'Antiquité ; depuis que la tolérance est uniforme, elle tombait
/// toujours APRÈS le zéro naturel et ne pouvait plus se déclencher.
int scoreFor(int annee, int guess, Difficulty diff) {
  final ecart = (guess - annee).abs();
  final pts = (maxScore * math.exp(-ecart / tolerance(diff))).round();
  return pts.clamp(0, maxScore).toInt();
}

/// Verdict d'une manche. SOURCE UNIQUE : le badge de révélation, la
/// couleur des points, le trait d'écart, la pastille de manche, la grille
/// emoji de partage et la série se calent tous dessus. Sans ça, le même
/// écran pouvait annoncer « dans la cible 🎯 » en menthe et « série
/// perdue » juste en dessous.
enum Verdict { reussi, moyen, rate }

Verdict verdictFor(int base) => base >= 700
    ? Verdict.reussi
    : base >= 350
        ? Verdict.moyen
        : Verdict.rate;

/// La dernière manche d'une partie classique/quotidienne vaut double.
int roundMultiplier(int roundIndex, {bool chrono = false}) {
  return (!chrono && roundIndex == rounds - 1) ? 2 : 1;
}
