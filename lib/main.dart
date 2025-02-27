import 'package:flutter/material.dart';
import 'package:met_museum_explorer/ui/screens/home_screen.dart';

void main() {
  runApp(const MetMuseumExplorer());
}

class MetMuseumExplorer extends StatelessWidget {
  const MetMuseumExplorer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Met Museum Explorer',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
} 