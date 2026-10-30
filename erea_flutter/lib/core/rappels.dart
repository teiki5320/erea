import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/store.dart';

/// Rappel du soir pour le défi du jour. 100 % local : rien ne sort de
/// l'appareil, aucun serveur, aucune donnée transmise.
///
/// Trois règles de politesse, tenues ici :
/// - l'autorisation n'est demandée qu'APRÈS un défi terminé avec une série
///   d'au moins 2 jours, jamais au premier lancement ;
/// - le message parle de la SÉRIE, pas de l'app : sans série en cours, il
///   n'y a rien à rappeler ;
/// - il ne promet jamais l'avenir : un seul rappel est programmé, le soir
///   où la série est en jeu, avec son nombre de jours exact.
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
          // Silhouette blanche : Android teinte l'icône des notifications,
          // l'icône couleur de l'app s'y affichait en carré blanc.
          android: AndroidInitializationSettings('@drawable/ic_stat_erea'),
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
      if (ios != null) {
        return await ios.requestPermissions(alert: true, sound: true) ?? false;
      }
      // Android 13 réclame la même autorisation à l'exécution. Sans elle,
      // la programmation réussit sans lever d'erreur et rien n'est jamais
      // délivré : le rappel du soir serait muet sans qu'on le voie. Avant
      // 13, l'appel ne fait rien et l'autorisation est déjà acquise.
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? false;
    } catch (e) {
      debugPrint('Autorisation refusée ou indisponible : $e');
      return false;
    }
  }

  /// Le soir où la série est en jeu, en heure locale — ou `null` s'il n'y
  /// a rien à rappeler.
  ///
  /// - Défi terminé aujourd'hui : la série court jusqu'à demain soir.
  /// - Tentative du jour perdue (abandon) : la série s'éteint à minuit,
  ///   plus rien ne peut la sauver.
  /// - Sinon : ce soir, si l'heure n'est pas passée.
  ///
  /// Un seul soir, jamais plusieurs : programmer « 🔥 6 jours » pour
  /// après-demain supposait le défi de demain joué, et un jour sauté
  /// laissait partir des rappels pour une série déjà morte.
  static DateTime? soirEnJeu({
    required DateTime maintenant,
    required int serie,
    required bool defiFaitAujourdhui,
    required bool tentativePerdue,
    int heure = 18,
    int minute = 30,
  }) {
    if (serie <= 0) return null;
    if (defiFaitAujourdhui) {
      return DateTime(maintenant.year, maintenant.month, maintenant.day + 1,
          heure, minute);
    }
    if (tentativePerdue) return null;
    final ceSoir = DateTime(
        maintenant.year, maintenant.month, maintenant.day, heure, minute);
    return ceSoir.isAfter(maintenant) ? ceSoir : null;
  }

  /// Remet le rappel d'aplomb d'après l'état du joueur. Appelé à chaque
  /// lancement de l'app, en fin de défi et à l'abandon d'un défi.
  static Future<void> reprogrammer(Store store) async {
    if (!store.remindersOn) return;
    await programmer(
      serie: store.effectiveStreak,
      defiFaitAujourdhui: store.dailyFinishedToday,
      tentativePerdue: store.dailyAttemptLost,
    );
  }

  /// Annule tout rappel en attente et programme celui du [soirEnJeu].
  static Future<void> programmer({
    required int serie,
    required bool defiFaitAujourdhui,
    bool tentativePerdue = false,
  }) async {
    if (!await _preparer()) return;
    try {
      await _plugin.cancelAll();
      // tz.local n'est jamais configurée (elle vaut UTC par défaut) : un
      // « 18 h 30 » programmé ainsi sonnait à 8 h 30 à Papeete. On calcule
      // donc l'INSTANT ABSOLU depuis l'heure locale de l'appareil
      // (DateTime), puis on le convertit — le fuseau du libellé importe
      // peu, seul l'instant compte.
      final locale = DateTime.now();
      final cible = soirEnJeu(
        maintenant: locale,
        serie: serie,
        defiFaitAujourdhui: defiFaitAujourdhui,
        tentativePerdue: tentativePerdue,
      );
      if (cible == null) return;
      final quand = tz.TZDateTime.now(tz.UTC).add(cible.difference(locale));
      await _plugin.zonedSchedule(
        id: 0,
        title: serie == 1
            ? '🔥 Ta série d’un jour'
            : '🔥 Ta série de $serie jours',
        body: 'Le défi du jour t’attend — une minute suffit à la garder '
            'en vie.',
        scheduledDate: quand,
        notificationDetails: const NotificationDetails(
          iOS: DarwinNotificationDetails(),
          android: AndroidNotificationDetails('defi', 'Défi du jour',
              importance: Importance.defaultImportance,
              color: Color(0xFFF25B4D)),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
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
