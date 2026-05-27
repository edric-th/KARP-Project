import 'package:flutter/material.dart';

/// Renders an official brand logo from `assets/logos/`, falling back to a
/// clean brand-accurate badge when the asset file is not present yet.
///
/// Drop the official files into `assets/logos/` (google.png, esewa.png,
/// khalti.png, imepay.png, bank.png) and they will be used automatically.
enum Brand { google, esewa, khalti, imepay, bank }

class BrandLogo extends StatelessWidget {
  final Brand brand;
  final double size;

  const BrandLogo(this.brand, {super.key, this.size = 28});

  String get _asset {
    switch (brand) {
      case Brand.google:
        return 'assets/logos/google.png';
      case Brand.esewa:
        return 'assets/logos/esewa.png';
      case Brand.khalti:
        return 'assets/logos/khalti.png';
      case Brand.imepay:
        return 'assets/logos/imepay.png';
      case Brand.bank:
        return 'assets/logos/bank.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => _fallback(),
    );
  }

  Widget _fallback() {
    switch (brand) {
      case Brand.google:
        return _GoogleG(size: size);
      case Brand.esewa:
        return _WordmarkBadge(
          size: size,
          bg: const Color(0xFF60BB46),
          text: 'eSewa',
        );
      case Brand.khalti:
        return _WordmarkBadge(
          size: size,
          bg: const Color(0xFF5C2D91),
          text: 'K',
        );
      case Brand.imepay:
        return _WordmarkBadge(
          size: size,
          bg: const Color(0xFFD7252C),
          text: 'IME',
        );
      case Brand.bank:
        return _IconBadge(
          size: size,
          bg: const Color(0xFF1F4E8C),
          icon: Icons.account_balance_rounded,
        );
    }
  }
}

// ─── FALLBACKS ───────────────────────────────────────────────────────────────

class _WordmarkBadge extends StatelessWidget {
  final double size;
  final Color bg;
  final String text;
  const _WordmarkBadge({
    required this.size,
    required this.bg,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.26),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size * 0.12),
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: size * 0.42,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final double size;
  final Color bg;
  final IconData icon;
  const _IconBadge({required this.size, required this.bg, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.26),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white, size: size * 0.56),
    );
  }
}

/// A faithful, asset-free Google "G" drawn with a CustomPainter.
class _GoogleG extends StatelessWidget {
  final double size;
  const _GoogleG({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final stroke = w * 0.205;
    final radius = (w - stroke) / 2;
    final center = Offset(w / 2, w / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    double rad(double deg) => deg * 3.1415926535 / 180.0;

    // Arcs around the ring (0° = 3 o'clock, clockwise positive).
    // Red — top
    p.color = _red;
    canvas.drawArc(rect, rad(-122), rad(80), false, p);
    // Yellow — left
    p.color = _yellow;
    canvas.drawArc(rect, rad(137), rad(75), false, p);
    // Green — bottom
    p.color = _green;
    canvas.drawArc(rect, rad(50), rad(87), false, p);
    // Blue — right (upper portion down toward the crossbar)
    p.color = _blue;
    canvas.drawArc(rect, rad(-20), rad(70), false, p);

    // Blue crossbar pointing into the centre from the right edge.
    final barHeight = stroke;
    final barLeft = center.dx + radius * 0.02;
    final barRight = center.dx + radius + stroke / 2;
    final barRect = Rect.fromLTRB(
      barLeft,
      center.dy - barHeight / 2,
      barRight,
      center.dy + barHeight / 2,
    );
    canvas.drawRect(barRect, Paint()..color = _blue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
