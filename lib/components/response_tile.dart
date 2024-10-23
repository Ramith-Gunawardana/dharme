import 'package:flutter/material.dart';

class ResponseTile extends StatelessWidget {
  final String title;
  final String icon;
  final Color color;
  const ResponseTile(
      {super.key,
      required this.title,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        border: Border.all(width: 1.0),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        leading: Icon(Icons.call),
        title: Text(title),
      ),
    );
  }
}
