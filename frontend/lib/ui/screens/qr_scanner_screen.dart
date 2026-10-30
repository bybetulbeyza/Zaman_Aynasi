import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/heritage_place.dart';
import '../../data/repositories/heritage_repository.dart';
import 'slider_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final HeritageRepository _repository = HeritageRepository();
  bool _isScannerOpen = false;
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? scannedValue = barcodes.first.rawValue;
    if (scannedValue == null || scannedValue.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      // Eserler arasından ID veya İsim eşleşmesini ara
      final places = await _repository.getPlaces();
      final matchedPlace = places.firstWhere(
            (p) =>
        p.id.toString() == scannedValue ||
            p.name.toLowerCase().trim() == scannedValue.toLowerCase().trim(),
        orElse: () => places.first, // Test ve demo için bulamazsa ilk eseri açar
      );

      if (mounted) {
        // Kamerayı kapatıp SliderScreen'e geç
        setState(() {
          _isScannerOpen = false;
          _isProcessing = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SliderScreen(
              title: matchedPlace.name,
              beforeImageUrl: matchedPlace.imageBeforeUrl,
              afterImageUrl: matchedPlace.imageAfterUrl,
              description: matchedPlace.shortDescription,
              hotspots: matchedPlace.hotspots,
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isScannerOpen) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => setState(() => _isScannerOpen = false),
          ),
          title: const Text(
            'Karekodu Hizalayın',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          centerTitle: true,
        ),
        body: Stack(
          alignment: Alignment.center,
          children: [
            MobileScanner(
              onDetect: _onDetect,
            ),
            // Tarama Çerçevesi
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryTeal, width: 2.5),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
      );
    }

    // Ekran Tasarımı (Birebir Görseldeki Tasarım)
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.bgCanvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'QR Okut',
          style: TextStyle(
            fontSize: 22,
            fontFamily: 'Serif',
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Büyük Dairesel QR İkon Alanı
              Container(
                width: 160,
                height: 160,
                decoration: const BoxDecoration(
                  color: Color(0xFFD6F0F0), // Görseldeki pastel açık turkuaz/teal
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 76,
                  color: AppColors.primaryTealDark,
                ),
              ),

              const SizedBox(height: 36),

              // Başlık
              const Text(
                'Tabeladaki karekodu okut',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 18),

              // Açıklama Kartı
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle, width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'Tarihi yapının tabelasındaki karekodu okut. '
                      'Eserin sayfası önce/bugün fotoğrafıyla açılır. '
                      'Karekod yoksa Tarih Envanteri\'nden ara.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // "Kamerayı aç" Butonu
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _isScannerOpen = true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Kamerayı aç',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}