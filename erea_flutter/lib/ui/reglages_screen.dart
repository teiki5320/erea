import 'package:flutter/material.dart' hide Badge;

import '../core/achat.dart';
import '../core/classement.dart';
import '../core/pub.dart';
import '../core/rappels.dart';
import '../core/region.dart' as region;
import '../core/retour.dart';
import '../core/sons.dart';
import '../data/store.dart';
import '../game/badges.dart';
import 'onboarding_screen.dart'
    show OnboardingScreen, PaysPropose, paysProposes, drapeauIso;
import 'sticker_widgets.dart';

/// Réglages et succès. Un seul écran : le jeu n'a pas de quoi en remplir
/// deux, et tout ce qui s'y règle tient sur une page.
class ReglagesScreen extends StatefulWidget {
  const ReglagesScreen({super.key, required this.store});

  final Store store;

  @override
  State<ReglagesScreen> createState() => _ReglagesScreenState();
}

class _ReglagesScreenState extends State<ReglagesScreen> {
  @override
  Widget build(BuildContext context) {
    final obtenus = widget.store.badges;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Réglages & succès',
          style: TextStyle(
            fontFamily: 'Baloo2',
            fontWeight: FontWeight.w800,
            color: inkColor,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          _carteSansPub(),
          _cartePublicite(),
          _carte([
            SwitchListTile(
              value: widget.store.hapticsOn,
              onChanged: (v) async {
                await widget.store.setHapticsOn(v);
                Retour.actif = v;
                if (mounted) setState(() {});
              },
              title: const Text('Vibrations'),
              subtitle: const Text('Un cran par dizaine d’années, un choc à '
                  'la validation'),
            ),
            SwitchListTile(
              value: widget.store.soundOn,
              onChanged: (v) async {
                await widget.store.setSoundOn(v);
                Sons.actif = v;
                if (mounted) setState(() {});
              },
              title: const Text('Sons'),
              subtitle: const Text('Respecte le bouton silencieux de '
                  'l’iPhone'),
            ),
            SwitchListTile(
              value: widget.store.remindersOn,
              onChanged: (v) async {
                if (v) {
                  final ok = await Rappels.demanderAutorisation();
                  if (!ok) return;
                  await Rappels.programmer(
                    serie: widget.store.effectiveStreak,
                    defiFaitAujourdhui: widget.store.dailyFinishedToday,
                  );
                } else {
                  await Rappels.toutAnnuler();
                }
                await widget.store.setRemindersOn(v);
                if (mounted) setState(() {});
              },
              title: const Text('Rappel du soir'),
              subtitle: const Text('Seulement quand une série est en cours'),
            ),
            ListTile(
              title: const Text('Classement mondial'),
              subtitle: const Text('Défi du jour, série et records'),
              trailing: const Icon(Icons.emoji_events, color: yellowColor),
              onTap: () => Classement.afficher(tableau: Classement.defi),
            ),
            ListTile(
              title: const Text('Mon pays'),
              subtitle:
                  const Text('Le Classique met en avant l’histoire locale'),
              trailing: Text(
                widget.store.paysChoisiNom == null
                    ? '🌐 Automatique'
                    : '${drapeauIso(widget.store.paysChoisiIso)} '
                        '${widget.store.paysChoisiNom}',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: _choisirPays,
            ),
          ]),
          const SizedBox(height: 16),
          Text(
            'Succès  ${obtenus.length} / ${badges.length}',
            style: const TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: inkColor,
            ),
          ),
          const SizedBox(height: 8),
          _carte([
            for (final b in badges) _ligneSucces(b, obtenus.contains(b.cle)),
          ]),
          const SizedBox(height: 16),
          _carte([
            ListTile(
              title: const Text('Revoir la présentation'),
              subtitle: const Text('Les écrans du premier lancement'),
              trailing: const Icon(Icons.slideshow, color: skyColor),
              onTap: _revoirPresentation,
            ),
            ListTile(
              title: const Text('Tout remettre à zéro'),
              subtitle: const Text('Progression, records, collection et série'),
              trailing: const Icon(Icons.restart_alt, color: coralColor),
              onTap: _confirmerRAZ,
            ),
          ]),
          const SizedBox(height: 12),
          // ⚠️ Ne pas remettre « aucune donnée ne quitte cet appareil » :
          // c'était vrai jusqu'à l'arrivée de la publicité, la régie
          // collecte. Ta progression, elle, reste bien locale — et c'est
          // ce que dit désormais cette ligne, sans mentir sur le reste.
          const Center(
            child: Text(
              'Erea — ta progression reste sur cet appareil.',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: inkPaleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// L'achat « sans pub », en tête des réglages.
  ///
  /// Trois états, et jamais de bouton mort : rien du tout si la boutique
  /// est muette (avion, restrictions parentales, produit pas encore
  /// validé), un remerciement si c'est déjà payé, l'offre sinon.
  ///
  /// Le prix vient de la boutique, jamais d'une constante : il change avec
  /// le pays, la devise et les taxes.
  Widget _carteSansPub() {
    if (widget.store.sansPub) {
      return _carte([
        const ListTile(
          title: Text('Merci !'),
          subtitle: Text('Erea est sans publicité sur cet appareil, pour '
              'toujours'),
          trailing: Text('💛', style: TextStyle(fontSize: 22)),
        ),
      ]);
    }
    if (!Achat.disponible) return const SizedBox.shrink();
    return _carte([
      ListTile(
        title: const Text('Erea sans publicité'),
        subtitle: const Text('Un achat unique. Le jeu reste entier : c’est '
            'la publicité qui disparaît, rien ne se débloque'),
        trailing: Text(
          Achat.prix ?? '',
          style: const TextStyle(
            fontFamily: 'Baloo2',
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: coralColor,
          ),
        ),
        onTap: _acheter,
      ),
      // Obligatoire : Apple refuse une app qui ne permet pas de retrouver
      // un achat après changement d'appareil ou réinstallation.
      ListTile(
        dense: true,
        title: const Text('Restaurer mes achats'),
        trailing: const Icon(Icons.refresh, color: inkSoftColor),
        onTap: _restaurer,
      ),
    ]);
  }

  /// Le retour sur le consentement publicitaire.
  ///
  /// Google exige ce point d'entrée permanent partout où son formulaire
  /// s'est affiché : un accord qu'on ne peut plus retirer n'est pas un
  /// accord. Le SDK dit lui-même s'il le réclame (`optionsRequises`) —
  /// hors d'Europe, la ligne n'apparaît pas, et un acheteur ne la voit
  /// jamais puisqu'il n'a plus de publicité du tout.
  Widget _cartePublicite() {
    if (widget.store.sansPub || !Pub.optionsRequises) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _carte([
        const ListTile(
          title: Text('Publicité personnalisée'),
          subtitle: Text('Revenir sur le choix fait au premier lancement'),
          trailing:
              Icon(Icons.privacy_tip_outlined, color: inkSoftColor),
          onTap: Pub.ouvrirOptions,
        ),
      ]),
    );
  }

  Future<void> _acheter() async {
    final ouvert = await Achat.acheter();
    if (!mounted) return;
    if (!ouvert) {
      _dire('La boutique n’a pas répondu. Réessaie plus tard.');
      return;
    }
    // Le résultat arrive par le flux de la boutique, pas ici : on laisse
    // le temps à la transaction d'aboutir avant de redessiner.
    await Future<void>.delayed(const Duration(seconds: 1));
    if (mounted) setState(() {});
  }

  Future<void> _restaurer() async {
    await Achat.restaurer();
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {});
    _dire(widget.store.sansPub
        ? 'Achat retrouvé, merci !'
        : 'Aucun achat à restaurer sur ce compte.');
  }

  void _dire(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  /// Le fond blanc est porté par un [Material], pas par une décoration :
  /// un `Container` coloré autour d'un `ListTile` avale l'effet de
  /// pression, qui se peint sur le Material le plus proche. Les lignes
  /// tapables des réglages ne réagissaient donc pas au doigt.
  Widget _carte(List<Widget> enfants) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [softShadow],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: Column(children: enfants),
        ),
      );

  /// Changer de pays après coup : même liste qu'au premier lancement.
  /// « Un autre pays » = automatique (le réglage de l'appareil décide).
  Future<void> _choisirPays() async {
    final choix = await showModalBottomSheet<PaysPropose>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: 640,
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      builder: (context) => ListView(
        children: [
          for (final p in paysProposes)
            ListTile(
              leading: Text(drapeauIso(p.iso),
                  style: const TextStyle(fontSize: 22)),
              title: Text(p.nom),
              trailing: (p.iso == widget.store.paysChoisiIso &&
                      (p.iso != null || widget.store.paysChoisiIso == null))
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.of(context).pop(p),
            ),
        ],
      ),
    );
    if (choix == null) return;
    Sons.appui();
    await widget.store.setPaysChoisi(
      nom: choix.iso == null ? null : choix.nom,
      iso: choix.iso,
    );
    region.paysChoisiIso = choix.iso;
    if (mounted) setState(() {});
  }

  Widget _ligneSucces(Badge b, bool obtenu) => Opacity(
        opacity: obtenu ? 1 : 0.42,
        child: ListTile(
          leading: Text(
            obtenu ? b.emoji : '🔒',
            style: const TextStyle(fontSize: 24),
          ),
          title: Text(
            b.titre,
            style: const TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: inkColor,
            ),
          ),
          subtitle: Text(
            b.comment,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: inkSoftColor,
            ),
          ),
        ),
      );

  /// Rejouer le parcours d'accueil sans rien effacer : on revient aux
  /// réglages à la fin, et le pays éventuellement rechoisi est appliqué.
  Future<void> _revoirPresentation() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => OnboardingScreen(
          store: widget.store,
          onTermine: () => Navigator.of(context).pop(),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _confirmerRAZ() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tout remettre à zéro ?'),
        content: const Text(
          'Niveau, XP, records, collection, succès, série et pays choisi '
          'seront effacés : l’app redeviendra comme au premier jour. '
          'C’est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.store.resetAll();
    // Les réglages son/vibration sont des champs statiques chargés au
    // démarrage : après un clear(), le magasin repasse à « activé » par
    // défaut et l'interrupteur l'affiche, mais les statiques gardaient
    // l'ancienne valeur — bascule sans effet jusqu'au redémarrage. On les
    // resynchronise. Et les rappels du soir déjà programmés dans iOS
    // survivaient au reset, interrupteur pourtant éteint : on les annule.
    Sons.actif = widget.store.soundOn;
    Retour.actif = widget.store.hapticsOn;
    // Même piège pour le pays : la variable de `region` est chargée au
    // démarrage. Sans cette ligne, le Classique continuait de mettre en
    // avant l'ancien pays alors que l'écran affichait « Automatique ».
    region.paysChoisiIso = null;
    await Rappels.toutAnnuler();
    if (mounted) setState(() {});
  }
}
