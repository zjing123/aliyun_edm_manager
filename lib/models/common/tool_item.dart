import 'package:flutter/material.dart';

class ToolItem {
  final String title;
  final IconData icon;
  final Function(BuildContext) onTap;

  const ToolItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });
} 