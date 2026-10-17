import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum PlaceCategory { cami, han, hamam, cesme, turbe }

class HeritagePlace {
  final String id;
  final String name;
  final PlaceCategory category;
  final LatLng location;
  final String shortDescription;

  HeritagePlace({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.shortDescription,
  });

  Color get categoryColor {
    switch (category) {
      case PlaceCategory.cami:
        return const Color(0xFF0D9488);
      case PlaceCategory.han:
        return const Color(0xFFB45309);
      case PlaceCategory.hamam:
      case PlaceCategory.cesme:
        return const Color(0xFF0284C7);
      case PlaceCategory.turbe:
        return const Color(0xFF881337);
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case PlaceCategory.cami:
        return Icons.mosque;
      case PlaceCategory.han:
        return Icons.account_balance;
      case PlaceCategory.hamam:
      case PlaceCategory.cesme:
        return Icons.water_drop;
      case PlaceCategory.turbe:
        return Icons.temple_hindu;
    }
  }
}