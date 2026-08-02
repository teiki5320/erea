import 'package:flutter/material.dart';

import '../core/timeline_scale.dart';
import 'era_art.dart';
import 'era_theme.dart';

/// Jetons du design system « Sticker Arcade » (handoff §Design tokens).
const inkColor = Color(0xFF35406B);
const inkSoftColor = Color(0xFF5F6890);
const inkPaleColor = Color(0xFF8A90AC);
const coralColor = Color(0xFFF25B4D);
const yellowColor = Color(0xFFFFC94D);
const mintColor = Color(0xFF45CFB2);
const skyColor = Color(0xFF56A8F5);
const violetColor = Color(0xFF9B7BF7);
const orangeColor = Color(0xFFFF9F43);
const verdictMintColor = Color(0xFF2AA88E);
const navyShadowColor = Color(0xFF232B4C);
const softShadow = BoxShadow(
  offset: Offset(0, 10),
  blurRadius: 26,
  color: Color(0x1F35406B),
);
const pillShadow = BoxShadow(
  offset: Offset(0, 6),
  blurRadius: 16,
  color: Color(0x1F35406B),
);

/// Fond d'écran fondu : teinte A → teinte B (poids t) + texture de décor
/// en haut d'écran, presque invisible (0,30 max, floutée, masquée avant la
/// première carte). Reconstruit à CHAQUE changement de `frac`, sans
/// animation implicite — le fondu est une fonction pure de la position.
class EraBackdrop extends StatelessWidget {
  const EraBackdrop({
    super.key,
    required this.frac,
    this.textureHeight = 200,
    this.maskStops = const [0.0, 0.23, 0.75],
    this.textureAlignment = const Alignment(0, -0.32),
  });

  final double frac;
  final double textureHeight;
  final List<double> maskStops;
  final Alignment textureAlignment;

  Widget _texture(int era, double weight) {
    if (weight <= 0.001) return const SizedBox.shrink();
    // Version pré-floutée (calculée une fois au chargement) : aucun flou
    // GPU à payer pendant le glissement.
    final img = EraArt.bgBlur[era] ?? EraArt.bgFor(era);
    if (img == null) return const SizedBox.shrink();
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: textureHeight,
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.30 * weight,
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (r) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: const [Colors.black, Colors.black, Colors.transparent],
              stops: maskStops,
            ).createShader(r),
            child: RawImage(
              image: img,
              fit: BoxFit.cover,
              alignment: textureAlignment,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final blend = eraBlendAt(frac);
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: eraThemes[blend.a].tint),
        if (blend.t > 0.001)
          Opacity(
            opacity: blend.t,
            child: ColoredBox(color: eraThemes[blend.b].tint),
          ),
        _texture(blend.a, 1 - blend.t),
        _texture(blend.b, blend.t),
      ],
    );
  }
}

/// Pastille d'époque. Les deux pastilles (A et B) sont superposées,
/// chacune à son opacité : c'est ce qui les fait fondre l'une dans l'autre.
class EraPillPair extends StatelessWidget {
  const EraPillPair({super.key, required this.frac, this.bordered = true});

  final double frac;

  /// Accueil : bordure d'encre. Jeu : ombre douce sans bordure.
  final bool bordered;

  Widget _pill(int era, double weight) {
    final theme = eraThemes[era];
    return Opacity(
      opacity: weight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: bordered ? Border.all(color: inkColor, width: 2) : null,
          boxShadow: bordered ? null : const [pillShadow],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: theme.tint,
                shape: BoxShape.circle,
                border: Border.all(color: theme.ink, width: 1.5),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              theme.name,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1.3,
                color: theme.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final blend = eraBlendAt(frac);
    return SizedBox(
      height: 26,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _pill(blend.a, 1 - blend.t),
          if (blend.t > 0.001) _pill(blend.b, blend.t),
        ],
      ),
    );
  }
}

/// Bouton « pousse-bouton » : au toucher il s'enfonce de 3 px et son ombre
/// dure raccourcit. Avec « réduire les animations », simple changement de
/// teinte. `onPressed == null` = désactivé.
class PushButton extends StatefulWidget {
  const PushButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.color,
    this.gradient,
    this.shadowColor = inkColor,
    this.shadowHeight = 5,
    this.softShadowColor,
    this.radius = 20,
    this.padding = const EdgeInsets.all(14),
    this.border,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final Color? color;
  final Gradient? gradient;
  final Color shadowColor;
  final double shadowHeight;

  /// Si fourni, remplace l'ombre dure par une ombre douce colorée.
  final Color? softShadowColor;
  final double radius;
  final EdgeInsets padding;
  final BoxBorder? border;

  @override
  State<PushButton> createState() => _PushButtonState();
}

class _PushButtonState extends State<PushButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final reduce = MediaQuery.of(context).disableAnimations;
    final down = _pressed && enabled && !reduce;
    final shadow = widget.softShadowColor != null
        ? BoxShadow(
            offset: const Offset(0, 12),
            blurRadius: 26,
            color: widget.softShadowColor!.withValues(alpha: 0.35),
          )
        : BoxShadow(
            offset: Offset(0, down ? 2 : widget.shadowHeight),
            blurRadius: 0,
            color: widget.shadowColor,
          );
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.onPressed,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Transform.translate(
          offset: Offset(0, down ? 3 : 0),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              color: (_pressed && reduce && enabled)
                  ? widget.color?.withValues(alpha: 0.85)
                  : widget.color,
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(widget.radius),
              border: widget.border,
              boxShadow: [shadow],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Minimap : la frise entière en 12 px, remplie du dégradé des 6 teintes
/// aux proportions réelles de l'échelle, avec le curseur corail. Tapable
/// et glissable pour sauter directement à une position.
class MiniMap extends StatelessWidget {
  const MiniMap({super.key, required this.frac, required this.onChanged});

  final double frac;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final stops = <double>[];
    final colors = <Color>[];
    var from = 0.0;
    for (var i = 0; i < eraThemes.length; i++) {
      final to = i == eraThemes.length - 1 ? 1.0 : yearToFrac(eras[i].to);
      colors
        ..add(eraThemes[i].tint)
        ..add(eraThemes[i].tint);
      stops
        ..add(from)
        ..add(to);
      from = to;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        void jump(Offset local) =>
            onChanged((local.dx / w).clamp(0.0, 1.0).toDouble());
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => jump(d.localPosition),
          onHorizontalDragUpdate: (d) => jump(d.localPosition),
          child: SizedBox(
            // Zone tactile ≥ 44 px (la barre visible reste fine).
            height: 44,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: inkColor, width: 1.5),
                    gradient: LinearGradient(colors: colors, stops: stops),
                  ),
                ),
                Positioned(
                  left: (frac * w - 2).clamp(0.0, w - 4),
                  child: Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: coralColor,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(color: Colors.white70, spreadRadius: 1),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
