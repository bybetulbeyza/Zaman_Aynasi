import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../../core/analytics/analytics.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_lang.dart';
import '../../../core/state/passport.dart';
import '../../../core/state/passport_titles.dart';
import '../../../data/models/heritage_place.dart';
import '../common/app_toast.dart';
import '../common/dark_cancel.dart';
import '../common/pattern_background.dart';
import '../common/pill_button.dart';
import '../passport/stamp_widget.dart';

/// Paylaşılan kartların mantıksal boyutu: Instagram hikâyesi (1080×1920).
const double kShareW = 1080;
const double kShareH = 1920;

/// Kartın dış çerçevesi: uygulamanın çini desenli krem zemini, yazı ölçeği ve koyu mod etkilemez.
class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return DarkCancel(
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: SizedBox(
          width: kShareW,
          height: kShareH,
          child: PatternBackground(
            color: AppColors.bgCanvas,
            lineOpacity: 0.12,
            scale: 1.15,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(80, 110, 80, 90),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final String tag;
  const _CardHeader({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipOval(
          child: Image.asset(
            'assets/images/app_logo.png',
            width: 104,
            height: 104,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(width: 24),
        const Text(
          'Zaman Aynası',
          style: TextStyle(
            fontFamily: AppTheme.brandFont,
            fontSize: 58,
            fontWeight: FontWeight.w600,
            color: AppColors.logoNavy,
            letterSpacing: -0.4,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.ciniBordeauxLight,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: AppColors.ciniBordeaux.withValues(alpha: 0.45),
              width: 2.4,
            ),
          ),
          child: Text(
            tag.toUpperCase(),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
              color: AppColors.ciniBordeaux,
            ),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 46, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(60),
        border: Border.all(
          color: AppColors.ciniBordeaux.withValues(alpha: 0.4),
          width: 2.4,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w800,
          color: AppColors.ciniBordeaux,
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();
  @override
  Widget build(BuildContext context) => Text(
    context.t('share_footer'),
    style: const TextStyle(
      fontSize: 30,
      letterSpacing: 2,
      color: AppColors.textMuted,
    ),
  );
}

/// Tek mühür kartı: ortada büyük mühür, altında eser bilgisi ve pasaport sayısı.
class StampShareCard extends StatelessWidget {
  final HeritagePlace place;
  final int total;
  const StampShareCard({super.key, required this.place, required this.total});

  @override
  Widget build(BuildContext context) {
    final en = context.isEn;
    final n = Passport.instance.stampCount;
    final info = [
      if (place.constructionDate.isNotEmpty) place.constructionDate,
      if (place.patron.isNotEmpty) place.patron,
    ].join(' · ');
    return _CardShell(
      child: Column(
        children: [
          _CardHeader(tag: context.t('stamp_earned').replaceAll('!', '')),
          const Spacer(flex: 2),
          Container(
            width: 640,
            height: 640,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.75),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: SizedBox(
              width: 520,
              height: 520,
              child: FittedBox(
                child: StampWidget(place: place, earned: true, size: 190),
              ),
            ),
          ),
          const Spacer(flex: 2),
          Text(
            '${place.category.labelFor(en)} · ${place.city}'.toUpperCase(),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: 6,
              color: AppColors.ciniBordeaux,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            place.nameFor(en),
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              fontFamily: AppTheme.headingFont,
              fontSize: 104,
              height: 1.05,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          if (info.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              info,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 38, color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 56),
          _Pill(
            context
                .t('share_stamp_line')
                .replaceAll('{n}', '$n')
                .replaceAll('{total}', '$total'),
          ),
          const Spacer(),
          const _Footer(),
        ],
      ),
    );
  }
}

/// Pasaport özet kartı: unvan, mühür ızgarası ve toplam sayı.
class PassportShareCard extends StatelessWidget {
  final List<HeritagePlace> places;
  const PassportShareCard({super.key, required this.places});

  @override
  Widget build(BuildContext context) {
    final n = places.where((p) => Passport.instance.hasStamp(p.id)).length;
    final title = context.t(passportTitleKey(places));
    const cols = 5;
    return _CardShell(
      child: Column(
        children: [
          _CardHeader(tag: context.t('passport_title')),
          const SizedBox(height: 70),
          Text(
            context.t('share_title_label').toUpperCase(),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: 7,
              color: AppColors.ciniBordeaux,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTheme.headingFont,
              fontSize: 118,
              height: 1.05,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 56),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(36),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(48),
                  border: Border.all(
                    color: AppColors.ciniBordeaux.withValues(alpha: 0.3),
                    width: 2.4,
                  ),
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 18,
                  runSpacing: 22,
                  children: [
                    for (final p in places)
                      SizedBox(
                        width:
                            (kShareW - 160 - 72 - 18 * (cols - 1) - 12) / cols,
                        height:
                            (kShareW - 160 - 72 - 18 * (cols - 1) - 12) / cols,
                        child: FittedBox(
                          child: StampWidget(
                            place: p,
                            earned: Passport.instance.hasStamp(p.id),
                            size: 130,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 44),
          _Pill(
            context
                .t('passport_count')
                .replaceAll('{n}', '$n')
                .replaceAll('{total}', '${places.length}'),
          ),
          const SizedBox(height: 40),
          const _Footer(),
        ],
      ),
    );
  }
}

/// Kartın önizlemesini gösterir; "Paylaş" ile PNG olarak cihazın paylaşım penceresine verir.
Future<void> showShareCard(
  BuildContext context, {
  required Widget card,
  required String text,
  required String fileName,
  required String kind,
  String? placeId,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => _SharePreview(
      card: card,
      text: text,
      fileName: fileName,
      kind: kind,
      placeId: placeId,
    ),
  );
}

class _SharePreview extends StatefulWidget {
  final Widget card;
  final String text;
  final String fileName;
  final String kind;
  final String? placeId;
  const _SharePreview({
    required this.card,
    required this.text,
    required this.fileName,
    required this.kind,
    this.placeId,
  });

  @override
  State<_SharePreview> createState() => _SharePreviewState();
}

class _SharePreviewState extends State<_SharePreview> {
  final GlobalKey _key = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final boundary =
          _key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List bytes = data!.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.fileName}.png');
      await file.writeAsBytes(bytes, flush: true);
      Analytics.track(
        'share',
        placeId: widget.placeId,
        meta: {'kind': widget.kind},
      );
      await SharePlus.instance.share(
        ShareParams(
          text: widget.text,
          files: [XFile(file.path, mimeType: 'image/png')],
        ),
      );
    } catch (_) {
      if (mounted) {
        AppToast.show(
          context,
          context.t('share_failed'),
          icon: Icons.ios_share_rounded,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: h * 0.68),
            child: AspectRatio(
              aspectRatio: kShareW / kShareH,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: RepaintBoundary(key: _key, child: widget.card),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 280,
            child: PillButton(
              context.t('share_btn'),
              onPressed: _busy ? null : _share,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.t('ok_btn'),
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
