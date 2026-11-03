import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Uygulamadaki tüm kartların ortak şekli: sol üst ve sağ alt köşe sivri, sağ üst ve sol alt köşe
/// kıvrımlı. [round] kıvrımlı köşelerin yarıçapıdır (küçük satırlarda ~22, büyük kartlarda 34-44).
ShapeBorder appCardBorder({
  double round = 24,
  Color? side,
  double width = 1.2,
}) => ContinuousRectangleBorder(
  borderRadius: BorderRadius.only(
    topLeft: const Radius.circular(10),
    bottomRight: const Radius.circular(10),
    topRight: Radius.circular(round),
    bottomLeft: Radius.circular(round),
  ),
  side: BorderSide(color: side ?? AppColors.chipBorder, width: width),
);

/// Beyaz (ya da verilen) zeminli, ince çerçeveli ve hafif gölgeli ortak kart görünümü.
ShapeDecoration appCardDecoration({
  double round = 24,
  Color fill = Colors.white,
  Color? side,
  double width = 1.2,
  bool shadow = true,
}) => ShapeDecoration(
  color: fill,
  shape: appCardBorder(round: round, side: side, width: width),
  shadows: shadow
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ]
      : null,
);
