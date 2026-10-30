import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_links.dart';
import '../../core/constants/app_theme.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/state/active_route.dart';
import '../../core/utils/launcher_util.dart';
import '../../data/models/heritage_place.dart';
import '../widgets/common/lang_toggle.dart';
import '../widgets/common/section_title.dart';
import '../widgets/detail/audio_guide_player.dart';
import '../widgets/detail/video_dialog.dart';
import '../widgets/slider/split_slider_widget.dart';

/// Eser detayı: Dönem/Bugün karşılaştırma slider'ı, hotspot'lar ve alttan açılan bilgi sayfası.
class SliderScreen extends StatefulWidget {
  final HeritagePlace place;

  const SliderScreen({super.key, required this.place});

  @override
  State<SliderScreen> createState() => _SliderScreenState();
}

class _SliderScreenState extends State<SliderScreen> {
  static const double _sheetMin = 0.42;
  static const double _sheetMax = 0.9;

  final DraggableScrollableController _sheetController = DraggableScrollableController();
  Hotspot? _selectedHotspot;

  HeritagePlace get _place => widget.place;

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _expandSheet() {
    _sheetController.animateTo(
      _sheetMax,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  /// "Cilt 1, s. 37" -> İngilizcede "Vol. 1, p. 37"
  String _inventoryLabel(bool en) {
    final raw = _place.inventoryLocation;
    if (!en) return raw;
    return raw.replaceAll('Cilt', 'Vol.').replaceAll(RegExp(r's\.\s*'), 'p. ');
  }

  void _toggleRoute() {
    final route = ActiveRoute.instance;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    if (route.contains(_place)) {
      route.remove(_place);
      messenger.showSnackBar(SnackBar(content: Text(context.t('route_removed'))));
    } else {
      route.add(_place);
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.t('route_added').replaceAll('{n}', '${route.length}')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final en = context.isEn;

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Stack(
        children: [
          // 1. Dönem / Bugün karşılaştırma alanı
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.6,
            child: Stack(
              children: [
                SplitSliderWidget(
                  beforeImageUrl: _place.imageBeforeUrl,
                  afterImageUrl: _place.imageAfterUrl,
                  afterLabel: context.t('period_label'),
                  beforeLabel: context.t('today_label'),
                  hotspots: _place.hotspots,
                  onHotspotSelected: (h) => setState(() => _selectedHotspot = h),
                ),
                if (_selectedHotspot != null)
                  Positioned(
                    top: size.height * 0.15,
                    left: 20,
                    right: 20,
                    child: _buildHotspotPopup(_selectedHotspot!, en),
                  ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: 0.9),
                      radius: 22,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            size: 18, color: AppColors.textDark),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Alttan açılan bilgi sayfası
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: _sheetMin,
            minChildSize: _sheetMin,
            maxChildSize: _sheetMax,
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                color: AppColors.bgCanvas,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                children: _buildSheetContent(en),
              ),
            ),
          ),

          // 3. Sabit alt eylem çubuğu
          Positioned(left: 0, right: 0, bottom: 0, child: _buildActionBar()),
        ],
      ),
    );
  }

  List<Widget> _buildSheetContent(bool en) {
    final videoUrl = _place.videoFor(en);
    final audioUrl = _place.audioFor(en);
    final meta = <MapEntry<String, String>>[
      if (_place.constructionDate.isNotEmpty)
        MapEntry(context.t('period'), _place.constructionDate),
      if (_place.architect.isNotEmpty)
        MapEntry(context.t('architect'), _place.architect),
      if (_place.patron.isNotEmpty) MapEntry(context.t('patron'), _place.patron),
    ];

    return [
      // Tutamaç
      Center(
        child: Container(
          width: 52,
          height: 5,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.ciniBordeaux,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),

      // Başlık + dil
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(_place.nameFor(en), style: AppTheme.displayLarge.copyWith(fontSize: 28)),
          ),
          const SizedBox(width: 12),
          const LangToggle(),
        ],
      ),
      const SizedBox(height: 16),

      // Dönem / Mimar / Bani
      if (meta.isNotEmpty)
        Wrap(
          spacing: 32,
          runSpacing: 12,
          children: [for (final m in meta) _metaItem(m.key, m.value)],
        ),
      const SizedBox(height: 18),

      // Yukarı kaydır ipucu
      GestureDetector(
        onTap: _expandSheet,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.chipBorder),
          ),
          child: Text(
            '↑ ${context.t('swipe_up')}',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryTeal),
          ),
        ),
      ),
      const SizedBox(height: 22),

      // AI videosu
      _buildVideoCard(videoUrl),
      const SizedBox(height: 16),

      // Sesli rehber
      AudioGuidePlayer(key: ValueKey(audioUrl), url: audioUrl),
      const SizedBox(height: 26),

      // Tarihçe
      SectionTitle(context.t('history')),
      const SizedBox(height: 10),
      Text(
        _place.descriptionFor(en),
        style: const TextStyle(fontSize: 16, height: 1.55, color: AppColors.textDark),
      ),
      const SizedBox(height: 26),

      // Kaynakça
      SectionTitle(context.t('sources')),
      const SizedBox(height: 12),
      _buildSourceCard(en),
    ];
  }

  Widget _metaItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      ],
    );
  }

  Widget _buildVideoCard(String videoUrl) {
    final available = videoUrl.isNotEmpty;
    const radius = BorderRadius.all(Radius.circular(20));
    return GestureDetector(
      onTap: available ? () => showVideoDialog(context, videoUrl) : null,
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
              color: AppColors.ciniBordeaux.withValues(alpha: 0.45), width: 1.1),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                _place.imageAfterUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(color: AppColors.heroPetrol),
              ),
              Container(color: Colors.black.withValues(alpha: 0.28)),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.ciniBordeaux,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(context.t('ai_generated'),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: available ? 1 : 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    available ? Icons.play_arrow_rounded : Icons.hourglass_empty_rounded,
                    color: AppColors.primaryTeal,
                    size: 34,
                  ),
                ),
              ),
              Positioned(
                left: 14,
                bottom: 12,
                child: Text(
                  available ? context.t('transform_video') : context.t('video_soon'),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceCard(bool en) {
    final inventory = _inventoryLabel(en);
    return GestureDetector(
      onTap: () => LauncherUtil.openUrl(AppLinks.inventoryBooks),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.ciniBordeaux.withValues(alpha: 0.4), width: 1.1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.t('source_book'),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Text(
                    inventory.isNotEmpty ? inventory : context.t('source_label'),
                    style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(context.t('source_open'),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryTeal)),
                      const SizedBox(width: 4),
                      const Icon(Icons.open_in_new_rounded,
                          size: 14, color: AppColors.primaryTeal),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primaryTealLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(context.t('verified'),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryTeal)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.dividerLine, width: 1.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => LauncherUtil.openDirections(_place.location),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryTeal,
                side: const BorderSide(color: AppColors.primaryTeal, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              child: Text(context.t('directions')),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ListenableBuilder(
              listenable: ActiveRoute.instance,
              builder: (context, _) {
                final inRoute = ActiveRoute.instance.contains(_place);
                return ElevatedButton.icon(
                  onPressed: _toggleRoute,
                  icon: Icon(inRoute ? Icons.check_rounded : Icons.add_rounded, size: 20),
                  label: Text(inRoute ? context.t('in_route') : context.t('add_to_route')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: inRoute ? AppColors.primaryTealDark : AppColors.primaryTeal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Hotspot ---

  Widget _buildHotspotPopup(Hotspot hotspot, bool en) {
    final videoUrl = hotspot.videoFor(en);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  hotspot.titleFor(en),
                  style: const TextStyle(
                    fontFamily: AppTheme.headingFont,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedHotspot = null),
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.close, size: 20, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hotspot.descriptionFor(en),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showHotspotDetail(hotspot, en),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  child: Text('${context.t('see_details')} →'),
                ),
              ),
              if (videoUrl != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => showVideoDialog(context, videoUrl),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: Text(context.t('ai_story')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ciniBordeaux,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showHotspotDetail(Hotspot hotspot, bool en) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCanvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(hotspot.titleFor(en), style: AppTheme.titleLarge),
                const SizedBox(height: 14),
                Text(
                  hotspot.descriptionFor(en),
                  style: const TextStyle(
                      fontSize: 16, height: 1.6, color: AppColors.textDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
