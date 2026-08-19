/// Un événement historique de la base Erea.
class HistEvent {
  final int id;

  /// Année de l'événement (négatif = av. J.-C.), entre -3000 et 2025.
  final int annee;
  final String titre;

  /// Description SANS indice de date (affichée pendant la manche).
  final String desc;

  /// Catégorie : pouvoir | sciences | arts | quotidien.
  final String cat;
  final String emoji;

  /// Difficulté : 1 = connu des enfants, 2 = culture générale, 3 = pointu.
  final int niveau;

  /// Anecdote « Le savais-tu ? » (affichée APRÈS la réponse, peut citer des dates).
  final String fun;

  /// Pack à thème optionnel : egypte | asie | ameriques | espace | afrique.
  final String? pack;

  /// Continent optionnel : afrique | ameriques | asie | europe | oceanie.
  /// Réservé aux futures catégories géographiques (roue des pays).
  final String? continent;

  /// Pays de l'événement (libellé français), renseigné avec [continent].
  final String? pays;

  const HistEvent({
    required this.id,
    required this.annee,
    required this.titre,
    required this.desc,
    required this.cat,
    required this.emoji,
    required this.niveau,
    required this.fun,
    this.pack,
    this.continent,
    this.pays,
  });

  factory HistEvent.fromJson(Map<String, dynamic> json) {
    return HistEvent(
      id: json['id'] as int,
      annee: json['annee'] as int,
      titre: json['titre'] as String,
      desc: json['desc'] as String,
      cat: json['cat'] as String,
      emoji: json['emoji'] as String,
      niveau: (json['niveau'] as int?) ?? 2,
      fun: (json['fun'] as String?) ?? '',
      pack: json['pack'] as String?,
      continent: json['continent'] as String?,
      pays: json['pays'] as String?,
    );
  }
}
