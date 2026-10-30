import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedLanguage = 'TR';

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        content: Text(
          content,
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Kapat',
              style: TextStyle(
                color: AppColors.primaryTealDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F2), // Görseldeki krem/bej zemin rengi
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF8F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Padding(
          padding: EdgeInsets.only(left: 8.0, top: 8.0),
          child: Text(
            'Profil',
            style: TextStyle(
              fontSize: 26,
              fontFamily: 'Serif',
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          children: [
            // 1. Zümrüt Yeşili "Hesap Gerekmez" Kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.primaryTealDark, // Tasarımdaki zümrüt tonu
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryTealDark.withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hesap gerekmez',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tüm içeriklere giriş yapmadan ulaşabilirsiniz.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // 2. Menü Butonları
            _buildMenuItem(
              title: 'Hakkında ve kaynaklar',
              onTap: () {
                _showInfoDialog(
                  'Hakkında ve Kaynaklar',
                  'Zaman Aynası projesi; tarihi vakıf eserlerinin geçmişi ile günümüzdeki halini etkileşimli karşılaştırma ve konum bazlı akıllı rotalarla sunar.',
                );
              },
            ),
            const SizedBox(height: 12),

            _buildMenuItem(
              title: 'Projenin amacı',
              onTap: () {
                _showInfoDialog(
                  'Projenin Amacı',
                  'Kültürel mirasımızı dijital ortama aktararak ziyaretçilere tarihi derinliği modern teknolojilerle yaşatmayı amaçlar.',
                );
              },
            ),
            const SizedBox(height: 12),

            _buildMenuItem(
              title: 'Arşiv kaynakları',
              onTap: () {
                _showInfoDialog(
                  'Arşiv Kaynakları',
                  'Görsel ve metin içerikleri ilgili kurum arşivlerinden ve kamuya açık kültür envanterlerinden derlenmiştir.',
                );
              },
            ),
            const SizedBox(height: 12),

            // Dil Seçimi
            _buildLanguageMenuItem(),
            const SizedBox(height: 12),

            _buildMenuItem(
              title: 'Yazı boyutu ve kontrast',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Erişilebilirlik ayarları yakında eklenecek.')),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildMenuItem(
              title: 'Geri bildirim gönder',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Geri bildirim formu hazırlanıyor...')),
                );
              },
            ),
            const SizedBox(height: 24),

            // 3. Alt Dipnot
            const Text(
              'İçerikler Vakıf Katılım envanter\nkaynaklarından alınmıştır.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // 4. Alt Kısımdaki Motif
            Icon(
              Icons.local_florist_rounded,
              size: 42,
              color: AppColors.ciniBordeaux.withOpacity(0.85),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.015),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageMenuItem() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Dil',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedLanguage = 'TR'),
                child: Text(
                  'TR',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: _selectedLanguage == 'TR'
                        ? AppColors.primaryTealDark
                        : AppColors.textMuted,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '|',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.borderSubtle,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedLanguage = 'EN'),
                child: Text(
                  'EN',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: _selectedLanguage == 'EN'
                        ? AppColors.primaryTealDark
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}