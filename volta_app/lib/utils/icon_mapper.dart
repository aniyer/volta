import 'package:flutter/material.dart';

class IconMapper {
  static IconData getIcon(String name) {
    switch (name) {
      // Missions
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'local_dining':
        return Icons.local_dining;
      case 'auto_stories':
        return Icons.auto_stories;
      case 'water_drop':
        return Icons.water_drop;
      case 'delete_sweep':
        return Icons.delete_sweep;
      case 'local_florist':
        return Icons.local_florist;
      case 'local_laundry_service':
        return Icons.local_laundry_service;
      case 'air':
        return Icons.air;
      case 'star':
        return Icons.star;
        
      // Bazaar
      case 'monitor':
        return Icons.monitor;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'cookie':
        return Icons.cookie;
      case 'icecream':
        return Icons.icecream;
      case 'nights_stay':
        return Icons.nights_stay;
      case 'attach_money':
        return Icons.attach_money;
      case 'movie':
        return Icons.movie;
      case 'fast_forward':
        return Icons.fast_forward;
      case 'local_pizza':
        return Icons.local_pizza;
        
      // Defaut
      default:
        return Icons.help_outline;
    }
  }
}
