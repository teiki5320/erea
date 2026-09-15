import 'package:flutter/material.dart';

import 'sticker_widgets.dart';

/// Démonstration animée du geste, sur la page « Fais glisser la frise »
/// de la présentation. Une main tire la frise vers la gauche, l'année
/// défile sous l'aiguille, la main se retire, la vraie date se plante en
/// vert et les points s'affichent ; puis tout recommence.
///
/// Dessinée au trait, pas jouée : aucune vidéo, aucun paquet natif à
/// ajouter — la boucle tourne dans l'app, dans les couleurs du jeu, et
/// pèse zéro octet d'asset. Les testeurs Android reprochaient à la
/// présentation d'être quatre images fixes : c'est la réponse.
class DemoFrise extends StatefulWidget {
  const DemoFrise({super.key});

  /// Année de départ et année visée : Prise de la Bastille, 1789, que
  /// tout le monde situe — la démo doit se comprendre sans lire.
  static const int anneeDepart = 1900;
  static const int anneeCible = 1789;

  @override
  State<DemoFrise> createState() => _DemoFriseState();
}

class _DemoFriseState extends State<DemoFrise>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // « Réduire les animations » (réglage d'accessibilité) : la démo se
    // fige sur son image finale — la vraie date plantée, les points —
    // qui est aussi la plus parlante. C'est le même réglage que les
    // tests activent, ce qui leur évite d'attendre une boucle sans fin.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _ctrl.stop();
      _ctrl.value = _Phase.verdictPose;
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => CustomPaint(
          painter: _DemoPainter(_ctrl.value),
          size: Size.infinite,
        ),
      );
}

/// Les phases de la boucle, en fraction du cycle.
class _Phase {
  static const double mainArrive = 0.08;
  static const double glisseFin = 0.55;
  static const double mainPartie = 0.64;
  static const double verdictPose = 0.78;
  static const double fondu = 0.92;
}

class _DemoPainter extends CustomPainter {
  _DemoPainter(this.t);

  final double t;

  static const double _pxParAn = 2.4;

  /// Progression du glissé, adoucie : la main démarre et finit en
  /// douceur, comme un vrai doigt.
  double get _glisse {
    final u = ((t - _Phase.mainArrive) / (_Phase.glisseFin - _Phase.mainArrive))
        .clamp(0.0, 1.0);
    return Curves.easeInOut.transform(u);
  }

  double get _annee =>
      DemoFrise.anneeDepart +
      (DemoFrise.anneeCible - DemoFrise.anneeDepart) * _glisse;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final ligneY = h * 0.74;

    // Fondu de fin de boucle : tout s'efface pour que le redémarrage ne
    // saute pas.
    final alpha = t < _Phase.fondu
        ? 1.0
        : 1 - ((t - _Phase.fondu) / (1 - _Phase.fondu)).clamp(0.0, 1.0);
    // Le calque déborde du cadre, comme la bande qu'il contient (voir
    // _peindreFrise) : sinon il la rognerait au bord de la peinture.
    canvas.saveLayer((Offset.zero & size).inflate(18),
        Paint()..color = Colors.white.withValues(alpha: alpha));

    _peindreFrise(canvas, w, h, cx, ligneY);
    _peindreAnnee(canvas, cx, h);
    _peindreAiguille(canvas, cx, h, ligneY);
    _peindreVerdict(canvas, cx, ligneY);
    _peindreMain(canvas, w, ligneY);

    canvas.restore();
  }

  void _peindreFrise(Canvas canvas, double w, double h, double cx, double ligneY) {
    // Bande de la frise : deux teintes, la séparation d'époque glisse
    // avec les années pour que l'œil sente le mouvement.
    // La bande déborde du cadre de peinture : le conteneur de la page la
    // rogne à son bord arrondi, et la frise semble traverser la vignette
    // au lieu de flotter au milieu.
    const deb = 18.0;
    final bande = Rect.fromLTWH(-deb, ligneY - 34, w + 2 * deb, 68);
    final frontiere = cx + (1800 - _annee) * _pxParAn;
    canvas.drawRect(bande, Paint()..color = const Color(0xFFDDF3EC));
    canvas.drawRect(
      Rect.fromLTRB(frontiere.clamp(-deb, w + deb), bande.top, w + deb, bande.bottom),
      Paint()..color = const Color(0xFFFFE1B8),
    );

    final trait = Paint()
      ..color = inkColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-deb, ligneY), Offset(w + deb, ligneY), trait);

    // Crans tous les 10 ans, grands tous les 50 avec leur étiquette.
    final premiere = (_annee - (w / 2 + deb) / _pxParAn).floor() ~/ 10 * 10;
    final derniere = (_annee + (w / 2 + deb) / _pxParAn).ceil();
    for (var a = premiere; a <= derniere; a += 10) {
      final x = cx + (a - _annee) * _pxParAn;
      final grand = a % 50 == 0;
      canvas.drawLine(
        Offset(x, ligneY),
        Offset(x, ligneY - (grand ? 16 : 7)),
        trait..strokeWidth = grand ? 2.4 : 1.4,
      );
      if (grand) {
        _texte(canvas, '$a', Offset(x, ligneY + 8), 13, inkSoftColor,
            FontWeight.w700, 'Nunito');
      }
    }
  }

  void _peindreAnnee(Canvas canvas, double cx, double h) {
    _texte(canvas, '${_annee.round()}', Offset(cx, h * 0.01), 32, inkColor,
        FontWeight.w800, 'Baloo2');
  }

  void _peindreAiguille(Canvas canvas, double cx, double h, double ligneY) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, ligneY - 4), width: 5, height: 84),
        const Radius.circular(3),
      ),
      Paint()..color = coralColor,
    );
  }

  /// Après le glissé : le vrai 1789 se plante en vert sur la frise et la
  /// pastille des points surgit au-dessus, avec un petit rebond.
  void _peindreVerdict(Canvas canvas, double cx, double ligneY) {
    if (t < _Phase.mainPartie) return;
    final u = ((t - _Phase.mainPartie) / (_Phase.verdictPose - _Phase.mainPartie))
        .clamp(0.0, 1.0);
    final s = Curves.elasticOut.transform(u);
    const vert = Color(0xFF2FB27A);

    canvas.save();
    canvas.translate(cx, ligneY);
    canvas.scale(s);
    canvas.drawCircle(Offset.zero, 9, Paint()..color = vert);
    canvas.drawCircle(
        Offset.zero, 9, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.5);
    canvas.restore();

    canvas.save();
    canvas.translate(cx, ligneY - 50);
    canvas.scale(s);
    final pastille = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 132, height: 36),
      const Radius.circular(18),
    );
    canvas.drawRRect(pastille, Paint()..color = vert);
    _texte(canvas, 'Bravo ! +97 pts', Offset.zero, 15, Colors.white,
        FontWeight.w800, 'Baloo2', centreVertical: true);
    canvas.restore();
  }

  /// La main : arrive par la droite, tire vers la gauche, se retire.
  void _peindreMain(Canvas canvas, double w, double ligneY) {
    if (t >= _Phase.mainPartie) return;
    final arrivee = (t / _Phase.mainArrive).clamp(0.0, 1.0);
    final depart = t < _Phase.glisseFin
        ? 0.0
        : ((t - _Phase.glisseFin) / (_Phase.mainPartie - _Phase.glisseFin))
            .clamp(0.0, 1.0);
    final x = w * 0.72 - w * 0.44 * _glisse;
    final y = ligneY + 4 + 14 * (1 - arrivee) + 14 * depart;
    final opacite = arrivee * (1 - depart);
    // Un doigt dessiné, pas un émoji : le rendu des émojis change d'un
    // système à l'autre, et la présentation n'en utilise nulle part.
    // Le disque translucide est le « point de contact » qu'on voit dans
    // toutes les démos tactiles ; le trait blanc le rend lisible sur la
    // bande claire comme sur la bande orange.
    final centre = Offset(x, y);
    canvas.drawCircle(
        centre, 22, Paint()..color = inkColor.withValues(alpha: 0.28 * opacite));
    canvas.drawCircle(
        centre, 22,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9 * opacite)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    canvas.drawCircle(centre, 7, Paint()..color = inkColor.withValues(alpha: opacite));
  }

  void _texte(Canvas canvas, String s, Offset centre, double taille, Color couleur,
      FontWeight poids, String? police,
      {bool centreVertical = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
            fontSize: taille, color: couleur, fontWeight: poids, fontFamily: police),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(centre.dx - tp.width / 2,
          centreVertical ? centre.dy - tp.height / 2 : centre.dy),
    );
  }

  @override
  bool shouldRepaint(_DemoPainter old) => old.t != t;
}
