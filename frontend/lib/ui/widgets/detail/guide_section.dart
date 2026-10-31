import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_lang.dart';
import '../../../core/state/app_accessibility.dart';

/// Sesli rehber ve yazılı metni tek yerde sunar: kullanıcı "Dinle" ya da "Oku" seçer.
/// Seçim hatırlanır; işitme engelliler metni bir kez seçince her eserde metin açılır.
class GuideSection extends StatelessWidget {
  final Widget player; // ses oynatıcı
  final List<String> transcript;

  const GuideSection({
    super.key,
    required this.player,
    required this.transcript,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppAccessibility.instance,
      builder: (context, _) {
        final read = AppAccessibility.instance.readGuide;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Toggle(read: read),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              child: read
                  ? _Transcript(
                      key: const ValueKey('read'),
                      paragraphs: transcript,
                    )
                  : KeyedSubtree(key: const ValueKey('listen'), child: player),
            ),
          ],
        );
      },
    );
  }
}

class _Toggle extends StatelessWidget {
  final bool read;
  const _Toggle({required this.read});

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, IconData icon, bool selected, bool toRead) {
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => AppAccessibility.instance.setReadGuide(toRead),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryTeal : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 19,
                    color: selected ? Colors.white : AppColors.primaryTeal,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.primaryTeal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          seg(
            context.t('guide_listen'),
            Icons.headphones_rounded,
            !read,
            false,
          ),
          seg(context.t('guide_read'), Icons.menu_book_rounded, read, true),
        ],
      ),
    );
  }
}

class _Transcript extends StatelessWidget {
  final List<String> paragraphs;
  const _Transcript({super.key, required this.paragraphs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.chipBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t('guide_text_title'),
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < paragraphs.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            Text(
              paragraphs[i],
              style: const TextStyle(
                fontSize: 16.5,
                height: 1.6,
                color: AppColors.textDark,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
