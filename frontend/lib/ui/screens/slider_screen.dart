import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/slider/split_slider_widget.dart';

class SliderScreen extends StatelessWidget {
  final String title;
  final String beforeImageUrl;
  final String afterImageUrl;
  final String? description;

  const SliderScreen({
    super.key,
    required this.title,
    required this.beforeImageUrl,
    required this.afterImageUrl,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: AppColors.ciniBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SplitSliderWidget(
              beforeImageUrl: beforeImageUrl,
              afterImageUrl: afterImageUrl,
              beforeLabel: '1890 (Temsili Canlandırma)',
              afterLabel: '2026 Günümüz',
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description ??
                  'Erken Osmanlı dönemine ait almaşık taş-tuğla mimarisi ve 1958 sonrası hamamdan çarşıya dönüşüm süreci.',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}