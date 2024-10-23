import 'package:flutter/material.dart';
import 'package:senses/constants.dart';

class ResponseTile extends StatelessWidget {
  final String title;
  final String accuracy;
  final String iconName;
  final String hexColor;
  const ResponseTile(
      {super.key,
      required this.title,
      required this.iconName,
      required this.hexColor,
      required this.accuracy});

// Helper function for defining color
  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', ''); // Remove '#' if present
    if (hex.length == 6) {
      hex = 'FF$hex'; // Add 'FF' for full opacity
    }
    return Color(int.parse(hex, radix: 16));
  }

// Helper function for defining icon
  IconData _getIconData(String iconName) {
    Map<String, IconData> iconsMap = {
      'pets': Icons.pets,
      'home': Icons.home,
      'car': Icons.directions_car,
      'settings': Icons.settings,
    };

    return iconsMap[iconName] ?? Icons.help_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: _hexToColor(hexColor),
        border: Border.all(width: 1.0,color: kDeepBlueColor),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // Shadow color with transparency
            spreadRadius: 1, // How far the shadow spreads
            blurRadius: 6, // How soft the shadow is
            offset: const Offset(0, 4), // Offset in x and y direction
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(_getIconData(iconName)),
        title: Text(title),
        trailing: Text(accuracy),
      ),
    );
  }
}
