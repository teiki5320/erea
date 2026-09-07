/// Quand proposer l'achat « sans pub » après une publicité.
///
/// La règle, isolée du SDK et des widgets pour être vérifiable par un
/// test. Le moment est le seul qui convertisse vraiment : la pub vient
/// de se fermer, la gêne est fraîche. Mais une offre à chaque pub
/// deviendrait elle-même une nuisance — d'où trois garde-fous :
/// - une pub sur trois seulement, en commençant par la toute première ;
/// - un « Non merci » fait taire l'offre jusqu'au lendemain ;
/// - jamais si la boutique ne répond pas : pas de bouton mort.
library;

/// `pubsVues` compte la pub qui vient de se fermer (incrément AVANT
/// l'appel). `refuseeLe` est la clé de jour du dernier « Non merci ».
bool doitProposerOffre({
  required bool sansPub,
  required bool boutiqueDisponible,
  required int pubsVues,
  required String? refuseeLe,
  required DateTime maintenant,
}) {
  if (sansPub || !boutiqueDisponible) return false;
  if (pubsVues < 1 || pubsVues % 3 != 1) return false;
  if (refuseeLe == cleJour(maintenant)) return false;
  return true;
}

/// `2026-09-07` — la date seule, sans l'heure, pour comparer des jours.
String cleJour(DateTime d) {
  String deux(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${deux(d.month)}-${deux(d.day)}';
}
