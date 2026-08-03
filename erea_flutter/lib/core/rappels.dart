import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Rappel du soir pour le défi du jour. 100 % local : rien ne sort de
/// l'appareil, aucun serveur, aucune donnée transmise.
///
/// Deux règles de politesse, tenues ici :
/// - l'autorisation n'est demandée qu'APRÈS un premier défi terminé,
///   jamais au premier lancement ;
/// - le message parle de la SÉRIE, pas de l'app : sans série en cours, il
///   n'y a rien à rappeler.
class Rappels {
  Rappels._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _pret = false;

  static Future<bool> _preparer() async {
    if (_pret) return true;
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      _pret = true;
      return true;
    } catch (e) {
      debugPrint('Rappels indisponibles : $e');
      return false;
    }
  }

  /// Demande l'autorisation. À n'appeler qu'après un défi TERMINÉ.
  static Future<bool> demanderAutorisation() async {
    if (!await _preparer()) return false;
    try {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final ok = await ios?.requestPermissions(alert: true, sound: true);
      return ok ?? false;
    } catch (e) {
      debugPrint('Autorisation refusée ou indisponible : $e');
      return false;
    }
  }

  /// Reprogramme les rappels des sept prochains soirs. iOS plafonne les
  /// notifications en attente : une fenêtre glissante, régénérée à chaque
  /// ouverture, vaut mieux qu'une programmation infinie.
  static Future<void> programmer({
    required int serie,
    required bool defiFaitAujourdhui,
    int heure = 18,
    int minute = 30,
  }) async {
    if (!await _preparer()) return;
    try {
      await _plugin.cancelAll();
      // Sans série en cours, il n'y a rien à sauver : on ne dérange pas.
      if (serie <= 0) return;
      // tz.local n'est jamais configurée (elle vaut UTC par défaut) : un
      // « 18 h 30 » programmé ainsi sonnait à 8 h 30 à Papeete. On calcule
      // donc l'INSTANT ABSOLU depuis l'heure locale de l'appareil
      // (DateTime), puis on le convertit — le fuseau du libellé importe
      // peu, seul l'instant compte.
      final locale = DateTime.now();
      final maintenant = tz.TZDateTime.now(tz.UTC);
      for (var j = 0; j < 7; j++) {
        // Le défi du jour déjà joué : pas de rappel ce soir-là.
        if (j == 0 && defiFaitAujourdhui) continue;
        final cibleLocale = DateTime(
            locale.year, locale.month, locale.day + j, heure, minute);
        final quand = maintenant.add(cibleLocale.difference(locale));
        if (quand.isBefore(maintenant)) continue;
        await _plugin.zonedSchedule(
          id: j,
          title: '🔥 Ta série de ${serie + j} jours',
          body: 'Le défi du jour t’attend — une minute suffit à la garder '
              'en vie.',
          scheduledDate: quand,
          notificationDetails: const NotificationDetails(
            iOS: DarwinNotificationDetails(),
            android: AndroidNotificationDetails('defi', 'Défi du jour',
                importance: Importance.defaultImportance),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('Programmation des rappels impossible : $e');
    }
  }

  static Future<void> toutAnnuler() async {
    if (!await _preparer()) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
