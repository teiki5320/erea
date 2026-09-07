import 'package:flutter/material.dart';

import '../core/achat.dart';
import '../core/offre.dart';
import '../data/store.dart';
import 'sticker_widgets.dart';

/// L'offre « Erea sans publicité », partout où elle a une chance d'être
/// vue — et plus seulement enfouie dans les réglages, où personne ne va.
///
/// Trois formes, une seule source de vérité (`Store.sansPub` et
/// `Achat.disponible`) : rien ne s'affiche chez un acheteur, ni quand la
/// boutique est muette.
class OffreSansPub {
  OffreSansPub._();

  static bool visible(Store store) => !store.sansPub && Achat.disponible;

  /// La feuille de proposition. `apresPub` : un « Non merci » fait alors
  /// taire l'offre jusqu'au lendemain — quand le joueur l'ouvre lui-même
  /// depuis une pastille, refuser n'a rien à enregistrer.
  static Future<void> proposer(
    BuildContext context,
    Store store, {
    bool apresPub = false,
  }) async {
    if (!visible(store)) return;
    final achete = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFFFFF7E8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _Feuille(store: store, apresPub: apresPub),
    );
    if (achete != true && apresPub) {
      await store.setOffreRefuseeLe(cleJour(DateTime.now()));
    }
  }
}

class _Feuille extends StatefulWidget {
  const _Feuille({required this.store, required this.apresPub});
  final Store store;
  final bool apresPub;

  @override
  State<_Feuille> createState() => _FeuilleState();
}

class _FeuilleState extends State<_Feuille> {
  bool _enCours = false;

  Future<void> _acheter() async {
    setState(() => _enCours = true);
    final ouvert = await Achat.acheter();
    if (!mounted) return;
    if (!ouvert) {
      setState(() => _enCours = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('La boutique n’a pas répondu. Réessaie plus tard.'),
      ));
      return;
    }
    // Le résultat arrive par le flux de la boutique : on lui laisse le
    // temps d'aboutir avant de conclure.
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    Navigator.of(context).pop(widget.store.sansPub);
  }

  @override
  Widget build(BuildContext context) {
    final prix = Achat.prix ?? '';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.apresPub
                  ? 'Cette pub vous a gêné ?'
                  : 'Erea sans publicité',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Baloo2',
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: inkColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Un achat unique, une fois pour toutes. Le jeu reste entier : '
              'c’est la publicité qui disparaît, rien ne se débloque.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
                fontSize: 15,
                height: 1.4,
                color: inkSoftColor,
              ),
            ),
            const SizedBox(height: 18),
            PushButton(
              onPressed: _enCours ? () {} : _acheter,
              color: coralColor,
              shadowColor: const Color(0xFFB93A2F),
              radius: 16,
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Center(
                child: Text(
                  _enCours
                      ? 'Un instant…'
                      : 'Retirer la publicité — $prix',
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Non merci',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                  color: inkSoftColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La pastille discrète — accueil et écran de fin. Elle disparaît d'elle-
/// même après l'achat : elle relit l'état à chaque construction et se
/// redessine une fois la feuille refermée.
class OffreSansPubChip extends StatefulWidget {
  const OffreSansPubChip({super.key, required this.store});
  final Store store;

  @override
  State<OffreSansPubChip> createState() => _OffreSansPubChipState();
}

class _OffreSansPubChipState extends State<OffreSansPubChip> {
  @override
  Widget build(BuildContext context) {
    if (!OffreSansPub.visible(widget.store)) return const SizedBox.shrink();
    return Center(
      child: GestureDetector(
        onTap: () async {
          await OffreSansPub.proposer(context, widget.store);
          if (mounted) setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 7, 14, 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: inkColor, width: 2),
            boxShadow: const [
              BoxShadow(offset: Offset(0, 2), blurRadius: 0, color: inkColor),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.block, size: 15, color: coralColor),
              const SizedBox(width: 6),
              Text(
                'Sans pub · ${Achat.prix ?? ''}',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: inkColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
