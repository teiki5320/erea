import 'package:flutter/material.dart' hide Badge;

import '../core/classement.dart';
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
          const Center(
            child: Text(
              'Erea — aucune donnée ne quitte cet appareil.',
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

  Widget _carte(List<Widget> enfants) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [softShadow],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: enfants),
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
