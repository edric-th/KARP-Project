import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:frontend/constants/app_colors.dart';

/// Renders a doctor's photo from [photoUrl], which may be:
///  • a `data:image/...;base64,...` data-URL (set by the admin panel), or
///  • a normal http(s) URL, or
///  • empty → a person-icon placeholder.
/// On any decode/network error it falls back to the placeholder, so a bad
/// value never breaks the layout.
class DoctorAvatar extends StatelessWidget {
  final String photoUrl;
  final double size;
  final double? width; // overrides [size] when set (e.g. a full-width banner)
  final double? height; // overrides [size] when set
  final double borderRadius; // negative → fully circular
  final double? iconSize;

  const DoctorAvatar({
    super.key,
    required this.photoUrl,
    this.size = 48,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.iconSize,
  });

  bool get _isData => photoUrl.startsWith('data:');

  Uint8List? get _bytes {
    try {
      final comma = photoUrl.indexOf(',');
      if (comma < 0) return null;
      return base64Decode(photoUrl.substring(comma + 1));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = width ?? size;
    final h = height ?? size;
    final radius = borderRadius < 0
        ? BorderRadius.circular(w < h ? w : h)
        : BorderRadius.circular(borderRadius);

    Widget placeholder() => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: AppColors.cardGreenLight,
            borderRadius: radius,
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.person_rounded,
            color: AppColors.primary,
            size: iconSize ?? (w < h ? w : h) * 0.55,
          ),
        );

    if (photoUrl.trim().isEmpty) return placeholder();

    Widget image;
    if (_isData) {
      final bytes = _bytes;
      if (bytes == null) return placeholder();
      image = Image.memory(
        bytes,
        width: w,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder(),
      );
    } else {
      image = Image.network(
        photoUrl,
        width: w,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder(),
        loadingBuilder: (ctx, child, progress) =>
            progress == null ? child : placeholder(),
      );
    }

    return ClipRRect(borderRadius: radius, child: image);
  }
}
