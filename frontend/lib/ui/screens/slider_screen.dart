import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/heritage_place.dart';
import '../widgets/slider/split_slider_widget.dart';

class SliderScreen extends StatefulWidget {
  final String title;
  final String beforeImageUrl;
  final String afterImageUrl;
  final String? description;
  final String period;
  final String architect;
  final String patron;
  final String inventoryLocation; // örn. 'Cilt 1, s. 37'
  final String audioGuideUrl;
  final List<Hotspot> hotspots;

  const SliderScreen({
    super.key,
    required this.title,
    required this.beforeImageUrl,
    required this.afterImageUrl,
    this.description,
    this.period = '',
    this.architect = '',
    this.patron = '',
    this.inventoryLocation = '',
    this.audioGuideUrl = '',
    this.hotspots = const [],
  });

  /// Veri tabanındaki eserden tüm alanları taşıyarak ekranı açar.
  factory SliderScreen.fromPlace(HeritagePlace place) => SliderScreen(
        title: place.name,
        beforeImageUrl: place.imageBeforeUrl,
        afterImageUrl: place.imageAfterUrl,
        description: place.shortDescription,
        period: place.constructionDate,
        architect: place.architect,
        patron: place.patron,
        inventoryLocation: place.inventoryLocation,
        audioGuideUrl: place.audioGuideUrl,
        hotspots: place.hotspots,
      );

  @override
  State<SliderScreen> createState() => _SliderScreenState();
}

class _SliderScreenState extends State<SliderScreen> {
  bool _isEnglish = false;
  bool _isAudioPlaying = false;
  Hotspot? _selectedHotspot;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Stack(
        children: [
          // 1. Split-Slider Karşılaştırma Alanı (Üst Bölüm)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.58,
            child: Stack(
              children: [
                SplitSliderWidget(
                  beforeImageUrl: widget.beforeImageUrl,
                  afterImageUrl: widget.afterImageUrl,
                  hotspots: widget.hotspots,
                  onHotspotSelected: (hotspot) {
                    setState(() => _selectedHotspot = hotspot);
                  },
                ),

                // Seçilen Hotspot Bilgi Kartı
                if (_selectedHotspot != null)
                  Positioned(
                    top: size.height * 0.16,
                    left: 20,
                    right: 20,
                    child: _buildHotspotPopup(_selectedHotspot!),
                  ),

                // Geri ve Favori Butonları
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCircleActionButton(
                          icon: Icons.arrow_back_ios_new,
                          onTap: () => Navigator.pop(context),
                        ),
                        _buildCircleActionButton(
                          icon: Icons.favorite_border,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Alttan Açılan Detay Sayfası
          DraggableScrollableSheet(
            initialChildSize: 0.46,
            minChildSize: 0.44,
            maxChildSize: 0.88,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCanvas,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  children: [
                    // Tutamaç
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: AppColors.borderSubtle,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Başlık ve Dil Seçimi
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        _buildLanguageSelector(),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Dönem & Mimar
                    Row(
                      children: [
                        if (widget.period.isNotEmpty) _buildMetaItem('Dönem', widget.period),
                        if (widget.architect.isNotEmpty) _buildMetaItem('Mimar', widget.architect),
                        if (widget.patron.isNotEmpty) _buildMetaItem('Bani', widget.patron),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Sesli Rehber Oynatıcısı
                    _buildAudioGuidePlayer(),
                    const SizedBox(height: 20),

                    // Tarihçe
                    const Text(
                      'Tarihçe',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.description ??
                          'Bursa Vakıf Envanteri arşivlerinden derlenen mimari tarihçe ve vakfiye bilgileri.',
                      style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted, height: 1.5),
                    ),
                    const SizedBox(height: 20),

                    // Kaynakça Kartı
                    _buildSourceCard(),
                    const SizedBox(height: 20),

                    // Hızlı Aksiyon Butonları
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.navigation_outlined, size: 16),
                            label: const Text('Yol tarifi'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textDark,
                              side: const BorderSide(color: AppColors.chipBorder),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.add, size: 16, color: Colors.white),
                            label: const Text('Rotama ekle', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryTeal,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Yardımcı Widget Metotları ---

  Widget _buildCircleActionButton({required IconData icon, required VoidCallback onTap}) {
    return CircleAvatar(
      backgroundColor: Colors.white.withOpacity(0.88),
      radius: 20,
      child: IconButton(
        icon: Icon(icon, size: 18, color: AppColors.textDark),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildHotspotPopup(Hotspot hotspot) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  hotspot.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedHotspot = null),
                child: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            hotspot.description,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.35),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
                    ),
                    child: const Text('Detayları gör →', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ciniBordeaux,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('AI hikâyesi ', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                        Icon(Icons.play_arrow_rounded, size: 15, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.chipInactiveBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.chipBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isEnglish = false),
            child: Text(
              'TR',
              style: TextStyle(
                fontSize: 12,
                fontWeight: !_isEnglish ? FontWeight.bold : FontWeight.w400,
                color: !_isEnglish ? AppColors.primaryTeal : AppColors.textMuted,
              ),
            ),
          ),
          const Text(' | ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          GestureDetector(
            onTap: () => setState(() => _isEnglish = true),
            child: Text(
              'EN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: _isEnglish ? FontWeight.bold : FontWeight.w400,
                color: _isEnglish ? AppColors.primaryTeal : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        ],
      ),
    );
  }

  Widget _buildAudioGuidePlayer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isAudioPlaying = !_isAudioPlaying),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.ciniBordeaux,
              child: Icon(
                _isAudioPlaying ? Icons.pause : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sesli rehber', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                SizedBox(height: 4),
                LinearProgressIndicator(
                  value: 0.35,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 3,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Text('2:10', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSourceCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.verified_rounded, color: AppColors.primaryTeal, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kaynakça & Belge', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                Text('Vakıf Katılım Envanter Kitabı', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Doğrulandı', style: TextStyle(fontSize: 11, color: AppColors.primaryTeal, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}