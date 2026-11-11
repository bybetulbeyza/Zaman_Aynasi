import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../../../core/l10n/app_lang.dart';
import 'dark_cancel.dart';

/// "AI üretimi · Canlandırma" etiketi: fotoğraf üstünde bejimsi, yarı saydam buzlu cam.
class AiLabel extends StatelessWidget {
  final bool compact;
  const AiLabel({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF5E131E); // koyu bordo yazı: marka rengine bağlı kalır
    return DarkCancel(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: compact ? 5 : 7,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF6EEDD).withValues(alpha: 0.52),
              borderRadius: BorderRadius.circular(compact ? 12 : 16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 0.9,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: ink,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  context.t('ai_generated'),
                  style: TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 12 : 13,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
