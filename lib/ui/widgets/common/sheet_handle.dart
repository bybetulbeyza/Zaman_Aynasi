import 'package:flutter/material.dart';

/// Tüm kartların (alt sayfaların) üstündeki ortak tutamaç çizgisi.
/// [extraTop] kart tam ekran olunca durum çubuğunun altında kalmak için eklenir.
class SheetHandle extends StatelessWidget {
  final double extraTop;
  const SheetHandle({super.key, this.extraTop = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(0, 12 + extraTop, 0, 16),
      alignment: Alignment.topCenter,
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: const Color(0xFFCFC5B3), // sıcak, kremsi gri-bej
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

/// Alt sayfalar tabletlerde de ekranın tamamını kaplasın (ortada dar kalmasın).
const BoxConstraints kSheetConstraints = BoxConstraints(
  maxWidth: double.infinity,
);
