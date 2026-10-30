import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/location_service.dart';
import '../../data/models/heritage_place.dart';
import '../../data/repositories/heritage_repository.dart';

class RoutesScreen extends StatefulWidget {
  final Function(List<HeritagePlace>)? onRouteCreated;

  const RoutesScreen({super.key, this.onRouteCreated});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  final HeritageRepository _repository = HeritageRepository();

  String _selectedCity = 'Bursa';
  int _selectedHours = 2; // 1, 2, 3 saat

  // Çoklu kategori seçimi
  final List<String> _availableCategories = [
    'Cami',
    'Han',
    'Hamam',
    'Çeşme',
    'Türbe',
    'Medrese',
    'Müze',
  ];
  late Set<String> _selectedCategories;

  List<HeritagePlace> _allPlaces = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedCategories = {'Cami', 'Han'}; // Görseldeki varsayılan seçililer
    _fetchPlaces();
  }

  Future<void> _fetchPlaces() async {
    try {
      final places = await _repository.getPlaces();
      if (mounted) {
        setState(() {
          _allPlaces = places;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Dinamik durak sayısı tahmini (Süre ve kategoriye göre)
  int get _calculatedStopsCount {
    if (_allPlaces.isEmpty) return _selectedHours * 2;
    // Seçili kategorilere uyan eserleri say
    final matchingCount = _allPlaces.where((p) {
      return _selectedCategories.any((cat) =>
      p.category.label.toLowerCase().contains(cat.toLowerCase()) ||
          p.name.toLowerCase().contains(cat.toLowerCase()));
    }).length;

    // Saat başına ortalama 2-3 durak gezilebilir
    final maxByTime = _selectedHours * 3;
    final stops = matchingCount > 0 ? matchingCount.clamp(1, maxByTime) : (_selectedHours * 2);
    return stops;
  }

  Future<void> _handleCreateRoute() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryTeal),
      ),
    );

    final userLocation = await LocationService.getCurrentLocation();

    // Filtreleme: Seçili kategorilere göre eserleri al
    List<HeritagePlace> pool = _allPlaces.where((p) {
      if (_selectedCategories.isEmpty) return true;
      return _selectedCategories.any((cat) =>
      p.category.label.toLowerCase().contains(cat.toLowerCase()) ||
          p.name.toLowerCase().contains(cat.toLowerCase()));
    }).toList();

    if (pool.isEmpty) pool = List.from(_allPlaces);

    // TSP Algoritması ile zikzaksız sırala
    final optimized = LocationService.optimizeRouteOrder(
      places: pool,
      startLocation: userLocation,
    );

    // Süreye göre durak sayısını sınırla
    final finalRoute = optimized.take(_calculatedStopsCount).toList();

    if (mounted) {
      Navigator.pop(context); // Dialog kapat

      if (widget.onRouteCreated != null) {
        widget.onRouteCreated!(finalRoute);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('${finalRoute.length} duraklı özel rota oluşturuldu.'),
              ],
            ),
            backgroundColor: AppColors.primaryTeal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
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
            'Rota oluştur',
            style: TextStyle(
              fontSize: 26,
              fontFamily: 'Serif',
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
          : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          children: [
            // Ana Beyaz Form Kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderSubtle, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Şehir Seçimi
                  const Text(
                    'Şehir',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F3ED),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCity,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textDark, size: 20),
                        items: ['Bursa', 'İstanbul', 'Edirne', 'Konya'].map((city) {
                          return DropdownMenuItem(
                            value: city,
                            child: Text(
                              city,
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: AppColors.textDark),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCity = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Başlangıç Noktası
                  const Text(
                    'Başlangıç noktası',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F3ED),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFB3261E), // Kırmızı konum noktası
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Konumum',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: AppColors.textDark),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderSubtle, width: 0.8),
                          ),
                          child: const Text(
                            'Şimdi',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Süre Seçimi
                  const Text(
                    'Süre',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [1, 2, 3].map((hours) {
                      final isSelected = _selectedHours == hours;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: hours != 3 ? 8.0 : 0),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedHours = hours),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primaryTealDark : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isSelected ? AppColors.primaryTealDark : AppColors.borderSubtle,
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                '$hours saat',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : AppColors.textDark,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),

                  // Ne tür yerleri gezmek istersin?
                  const Text(
                    'Ne tür yerleri gezmek istersin?',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableCategories.map((cat) {
                      final isSelected = _selectedCategories.contains(cat);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              if (_selectedCategories.length > 1) {
                                _selectedCategories.remove(cat);
                              }
                            } else {
                              _selectedCategories.add(cat);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryTealDark : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryTealDark : AppColors.borderSubtle,
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textDark,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Dinamik Durak & Süre Özeti
                  Text(
                    'Yaklaşık $_calculatedStopsCount durak • $_selectedHours saat',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 14),

                  // Rota Oluştur Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _handleCreateRoute,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTealDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      ),
                      child: const Text(
                        'Rota oluştur',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Hazır Rota Yönlendirmesi
            const Text(
              'Hazır rota mı arıyorsun?',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tematik hazır rotalar listeleniyor...')),
                );
              },
              child: const Text(
                'Tarihi Rotalar\'a göz at',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTealDark,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Alt Kısımdaki Çini / Lale İllüstrasyonu (Görseldeki Gibi)
            Icon(
              Icons.local_florist_rounded,
              size: 42,
              color: AppColors.ciniBordeaux.withOpacity(0.85),
            ),
          ],
        ),
      ),
    );
  }
}