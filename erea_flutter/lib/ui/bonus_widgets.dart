import 'package:flutter/material.dart';

import '../core/bonus.dart';
import '../core/progression.dart';
import '../core/sons.dart';
import '../data/store.dart';
import 'icone.dart';
import 'sticker_widgets.dart';

/// Les écrans des bonus de niveau (1.0.8) : la rangée de la partie, la
/// ligne du stock de l'accueil, la feuille de choix et la carte de fin de
/// partie. Les règles vivent dans `lib/core/bonus.dart`.

/// Une icône de bonus et son nombre d'exemplaires en pastille.
class _PastilleBonus extends StatelessWidget {
  const _PastilleBonus({
    required this.type,
    required this.nombre,
    this.taille = 30,
    this.actif = false,
    this.eteint = false,
  });

  final BonusType type;
  final int nombre;
  final double taille;
  final bool actif;
  final bool eteint;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: eteint ? 0.32 : 1,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: taille + 22,
            height: taille + 10,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: actif ? const Color(0xFFFFF4EE) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: actif ? Border.all(color: coralColor, width: 3) : null,
              boxShadow: const [
                BoxShadow(offset: Offset(0, 2), color: Color(0xFFE9D3BC)),
              ],
            ),
            child: iconeNommee(type.icone, taille: taille),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18),
              height: 18,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: inkColor,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '$nombre',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// La rangée de bonus d'une manche, au-dessus de « Je place ici ».
///
/// Seuls les bonus découverts y figurent. Un bonus joué reste encadré de
/// corail jusqu'à la manche suivante ; les autres passent en gris, un seul
/// servant par partie.
class BarreBonus extends StatelessWidget {
  const BarreBonus({
    super.key,
    required this.niveau,
    required this.stock,
    required this.utilisable,
    required this.actifs,
    required this.onUtiliser,
    this.onPub,
  });

  final int niveau;
  final int Function(BonusType) stock;

  /// Un bonus peut-il encore servir dans cette manche ?
  final bool utilisable;

  /// Bonus en effet sur la manche en cours (encadrés).
  final Set<BonusType> actifs;
  final ValueChanged<BonusType> onUtiliser;

  /// « Regarder une pub : +1 bonus », ou null quand l'offre n'a pas lieu.
  final VoidCallback? onPub;

  @override
  Widget build(BuildContext context) {
    final decouverts = [
      for (final b in BonusType.values)
        if (estDecouvert(b, niveau)) b,
    ];
    return SizedBox(
      height: 52,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final b in decouverts)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Semantics(
                button: true,
                enabled: utilisable && stock(b) > 0,
                label: '${b.nom}, ${stock(b)} en stock. ${b.effet}.',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap:
                      utilisable && stock(b) > 0 ? () => onUtiliser(b) : null,
                  child: _PastilleBonus(
                    type: b,
                    nombre: stock(b),
                    taille: 26,
                    actif: actifs.contains(b),
                    eteint:
                        !actifs.contains(b) && (!utilisable || stock(b) == 0),
                  ),
                ),
              ),
            ),
          if (onPub != null)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Semantics(
                button: true,
                label: 'Regarder une publicité pour gagner un bonus',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: onPub,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4EE),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: coralColor, width: 2),
                    ),
                    child: const Text(
                      '▶ pub\n+1 bonus',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w800,
                        fontSize: 10.5,
                        height: 1.05,
                        color: coralColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// La ligne du stock sur l'accueil, sous la carte de niveau. Rien tant
/// qu'aucun bonus n'est découvert ; toucher la ligne ouvre l'explication.
class LigneStockBonus extends StatelessWidget {
  const LigneStockBonus({
    super.key,
    required this.store,
    required this.niveau,
    required this.onChoisir,
  });

  final Store store;
  final int niveau;
  final VoidCallback onChoisir;

  @override
  Widget build(BuildContext context) {
    final decouverts = [
      for (final b in BonusType.values)
        if (estDecouvert(b, niveau)) b,
    ];
    if (decouverts.isEmpty) return const SizedBox.shrink();
    final aChoisir = store.bonusAChoisir;
    return Row(
      children: [
        Flexible(
          child: Semantics(
            button: true,
            label: 'Mes bonus : ${[
              for (final b in decouverts) '${b.nom} ${store.bonus(b)}'
            ].join(', ')}. Toucher pour en savoir plus.',
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => expliquerBonus(context, store, niveau),
              child: Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  for (final b in decouverts)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        iconeNommee(b.icone, taille: 22),
                        const SizedBox(width: 2),
                        Text(
                          '${store.bonus(b)}',
                          style: const TextStyle(
                            fontFamily: 'Baloo2',
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: inkColor,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        if (aChoisir > 0) ...[
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onChoisir,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: coralColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                aChoisir == 1
                    ? 'Un bonus à choisir'
                    : '$aChoisir bonus à choisir',
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Titre extends StatelessWidget {
  const _Titre(this.texte, {this.couleur = inkColor});

  final String texte;
  final Color couleur;

  @override
  Widget build(BuildContext context) => Text(
        texte,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Baloo2',
          fontWeight: FontWeight.w800,
          fontSize: 24,
          color: couleur,
        ),
      );
}

const _sousTexte = TextStyle(
  fontFamily: 'Nunito',
  fontWeight: FontWeight.w700,
  fontSize: 13,
  height: 1.3,
  color: inkSoftColor,
);

/// Tous les bonus, découverts ou à venir : ce que chacun fait et à quel
/// niveau il arrive. Un bonus pas encore découvert garde son nom — c'est
/// ce qui donne envie de monter.
Future<void> expliquerBonus(
    BuildContext context, Store store, int niveau) async {
  Sons.appui();
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxWidth: 640,
      maxHeight: MediaQuery.sizeOf(context).height * .85,
    ),
    builder: (context) => ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      children: [
        const _Titre('Mes bonus'),
        const SizedBox(height: 4),
        const Text(
          'Un bonus par partie, jamais dans le Défi du jour. Une partie '
          'aidée n’entre pas dans les records.',
          textAlign: TextAlign.center,
          style: _sousTexte,
        ),
        for (final b in BonusType.values) ...[
          const SizedBox(height: 10),
          Opacity(
            opacity: estDecouvert(b, niveau) ? 1 : 0.45,
            child: Row(
              children: [
                iconeNommee(b.icone, taille: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.nom,
                        style: const TextStyle(
                          fontFamily: 'Baloo2',
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: inkColor,
                        ),
                      ),
                      Text(b.effet, style: _sousTexte),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  estDecouvert(b, niveau)
                      ? '${store.bonus(b)} / $stockMax'
                      : 'niveau ${b.niveau}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    color: inkPaleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

/// Feuille « Choisis ton bonus » : parmi les bonus découverts, sauf ceux
/// dont le stock est plein. Ajoute le bonus choisi et le rend ; rend null
/// si le joueur referme sans choisir, ou si tout est plein.
Future<BonusType?> choisirBonus(
  BuildContext context,
  Store store,
  int niveau, {
  required String titre,
}) async {
  final options = choisissables(niveau);
  final choix = await showModalBottomSheet<BonusType>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxWidth: 640,
      maxHeight: MediaQuery.sizeOf(context).height * .85,
    ),
    builder: (context) => ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      children: [
        _Titre(titre, couleur: coralColor),
        const SizedBox(height: 4),
        const Text(
          'Choisis ton bonus. Tu en gardes $stockMax au plus de chaque.',
          textAlign: TextAlign.center,
          style: _sousTexte,
        ),
        for (final b in options) ...[
          const SizedBox(height: 8),
          _optionChoix(context, b, store.bonus(b)),
        ],
      ],
    ),
  );
  if (choix == null) return null;
  await store.ajouterBonus(choix);
  return choix;
}

/// Les bonus gagnés en attente de choix, un par un, jusqu'à ce que le
/// joueur referme la feuille.
Future<void> choisirBonusEnAttente(BuildContext context, Store store) async {
  final niveau = levelFromXp(store.xp).level;
  while (store.bonusAChoisir > 0) {
    if (!context.mounted) return;
    final b = await choisirBonus(context, store, niveau,
        titre: 'Niveau $niveau !');
    if (b == null) return;
    await store.setBonusAChoisir(store.bonusAChoisir - 1);
  }
}

Widget _optionChoix(BuildContext context, BonusType b, int stock) {
  final plein = stock >= stockMax;
  return Opacity(
    opacity: plein ? 0.4 : 1,
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: plein ? null : () => Navigator.of(context).pop(b),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFECE6DD), width: 2),
          ),
          child: Row(
            children: [
              iconeNommee(b.icone, taille: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.nom,
                      style: const TextStyle(
                        fontFamily: 'Baloo2',
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: inkColor,
                      ),
                    ),
                    Text(b.effet, style: _sousTexte),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                plein ? 'complet' : '$stock / $stockMax',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  color: inkPaleColor,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Carte de fin de partie : les bonus découverts ou offerts par les
/// niveaux franchis, et le bouton des bonus à choisir.
class CarteRecompenses extends StatelessWidget {
  const CarteRecompenses({
    super.key,
    required this.recompenses,
    required this.aChoisir,
    required this.onChoisir,
  });

  final Recompenses recompenses;
  final int aChoisir;
  final VoidCallback onChoisir;

  @override
  Widget build(BuildContext context) {
    final lignes = <Widget>[
      for (final b in recompenses.decouvertes)
        _ligne(
            b,
            'Nouveau bonus découvert',
            '${b.effet}. Un bonus par '
                'partie, pas dans le Défi du jour.'),
      if (recompenses.xpDouble > 0)
        _ligne(BonusType.xpDouble, 'Cadeau de titre', BonusType.xpDouble.effet),
    ];
    if (lignes.isEmpty && aChoisir == 0) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: yellowColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...lignes,
          if (aChoisir > 0)
            Padding(
              padding: EdgeInsets.only(top: lignes.isEmpty ? 0 : 10),
              child: PushButton(
                onPressed: onChoisir,
                color: coralColor,
                shadowColor: const Color(0xFFB93A2F),
                radius: 16,
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Center(
                  child: Text(
                    aChoisir == 1
                        ? 'Choisir mon bonus'
                        : 'Choisir mes $aChoisir bonus',
                    style: const TextStyle(
                      fontFamily: 'Baloo2',
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ligne(BonusType b, String entete, String texte) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            iconeNommee(b.icone, taille: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entete.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w900,
                      fontSize: 11.5,
                      letterSpacing: 1,
                      color: Color(0xFFA9761C),
                    ),
                  ),
                  Text(
                    '${b.nom} ×1',
                    style: const TextStyle(
                      fontFamily: 'Baloo2',
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: inkColor,
                    ),
                  ),
                  Text(texte, style: _sousTexte),
                ],
              ),
            ),
          ],
        ),
      );
}
