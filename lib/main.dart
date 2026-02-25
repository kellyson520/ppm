import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/lock_screen.dart';
import 'ui/screens/vault_screen.dart';
import 'ui/screens/setup_screen.dart';
import 'services/vault_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1A1A2E),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const ZTDPasswordManagerApp());
}

class ZTDPasswordManagerApp extends StatelessWidget {
  const ZTDPasswordManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZTD Password Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        cardColor: const Color(0xFF16213E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A2E),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0F3460),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF6C63FF),
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white70,
        ),
        fontFamily: 'Inter',
      ),
      home: const AppNavigator(),
    );
  }
}

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  final VaultService _vaultService = VaultService();
  AppState _appState = AppState.loading;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final isInitialized = await _vaultService.isInitialized();
      
      setState(() {
        _appState = isInitialized ? AppState.locked : AppState.setup;
      });
    } on Exception {
      setState(() {
        _appState = AppState.error;
      });
    }
  }

  void _onSetupComplete() {
    setState(() {
      _appState = AppState.unlocked;
    });
  }

  void _onUnlocked() {
    setState(() {
      _appState = AppState.unlocked;
    });
  }

  void _onLocked() {
    setState(() {
      _appState = AppState.locked;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_appState) {
      case AppState.loading:
        return const SplashScreen();
      case AppState.setup:
        return SetupScreen(
          vaultService: _vaultService,
          onSetupComplete: _onSetupComplete,
        );
      case AppState.locked:
        return LockScreen(
          vaultService: _vaultService,
          onUnlocked: _onUnlocked,
        );
      case AppState.unlocked:
        return VaultScreen(
          vaultService: _vaultService,
          onLockRequested: _onLocked,
        );
      case AppState.error:
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to initialize vault',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _initializeApp,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
    }
  }

  @override
  void dispose() {
    _vaultService.dispose();
    super.dispose();
  }
}

enum AppState {
  loading,
  setup,
  locked,
  unlocked,
  error,
}
