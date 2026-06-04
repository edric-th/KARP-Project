import 'package:flutter/material.dart';

/// The official Mero पालो app logo (`assets/logos/logo.png`).
///
/// By default the logo is rendered on a clean white rounded card so it reads
/// well against coloured / dark backgrounds (splash, login, etc.). Set
/// [card] to `false` to draw the bare image. Falls back to a branded icon if
/// the asset is ever missing.
class AppLogo extends StatelessWidget {
  /// Overall size of the (square) logo, including the card padding.
  final double size;

  /// Corner radius of the white card. Ignored when [card] is `false`.
  final double borderRadius;

  /// Inner padding between the card edge and the logo image.
  final EdgeInsetsGeometry padding;

  /// Whether to wrap the logo in a white rounded card.
  final bool card;

  /// Whether the white card casts a soft drop shadow. Ignored when [card]
  /// is `false`.
  final bool shadow;

  const AppLogo({
    super.key,
    this.size = 120,
    this.borderRadius = 28,
    this.padding = const EdgeInsets.all(14),
    this.card = true,
    this.shadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/logos/logo.png',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, _, _) => const FittedBox(
        fit: BoxFit.contain,
        child: Icon(Icons.local_hospital_rounded, color: Color(0xFF15825F)),
      ),
    );

    if (!card) {
      return SizedBox(width: size, height: size, child: image);
    }

    return Container(
      width: size,
      height: size,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: image,
    );
  }
}
