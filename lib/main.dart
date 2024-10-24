import 'package:flutter/material.dart';
import 'package:senses/pages/home.dart';
import 'package:senses/pages/listening_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(fontFamily: "Poppins"),
      debugShowCheckedModeBanner: false,
      home: const Home(),
    );
  }
}