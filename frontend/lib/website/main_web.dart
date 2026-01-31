import 'package:flutter/material.dart';
import 'landing_page.dart';

void main() {
  runApp(const CogniCareWebsite());
}

class CogniCareWebsite extends StatelessWidget {
  const CogniCareWebsite({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CogniCare - Cognitive Health Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: const LandingPage(),
    );
  }
}
