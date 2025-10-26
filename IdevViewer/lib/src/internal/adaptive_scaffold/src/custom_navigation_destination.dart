import 'package:flutter/material.dart';

class CustomNavigationDestination {
  final Widget icon;
  final Widget selectedIcon;
  final String label;
  final List<CustomNavigationDestination>? subDestinations;

  CustomNavigationDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.subDestinations,
  });
}
