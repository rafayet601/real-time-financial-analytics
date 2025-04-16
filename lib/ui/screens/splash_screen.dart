import 'dart:async';
import 'package:flutter/material.dart';
import 'package:met_museum_explorer/services/cache_service.dart';
import 'package:met_museum_explorer/services/ml_service.dart';
import 'package:met_museum_explorer/services/met_museum_service.dart';
import 'package:met_museum_explorer/ui/screens/scanner_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _loadingMessage = 'Initializing...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() => _loadingMessage = 'Loading preferences...');
      final prefs = await SharedPreferences.getInstance();

      setState(() => _loadingMessage = 'Initializing services...');
      final cacheService = CacheService(prefs);
      final metService = MetMuseumService();
      final mlService = MLService();

      setState(() => _loadingMessage = 'Loading ML model...');
      await mlService.loadModel();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MultiProvider(
            providers: [
              Provider.value(value: cacheService),
              Provider.value(value: metService),
              Provider.value(value: mlService),
            ],
            child: const ScannerScreen(),
          ),
        ),
      );
    } catch (e) {
      print('Initialization Error: $e');
      setState(() {
        _loadingMessage = 'Failed to initialize. Please restart the app.';
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.museum, size: 80, color: Colors.white),
              const SizedBox(height: 20),
              Text(
                'Met Museum Explorer',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 40),
              if (!_hasError)
                const CircularProgressIndicator(color: Colors.white)
              else
                Icon(Icons.error_outline, color: Colors.red[300], size: 40),
              const SizedBox(height: 20),
              Text(
                _loadingMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 