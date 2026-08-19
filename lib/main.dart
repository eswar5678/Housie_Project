import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Enterprise: lock the whole app to landscape ─────────────────────────
  // (Android's manifest also declares sensorLandscape as a native fallback.)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.toString()}');
  };

  try {
    debugPrint('Initializing Firebase...');
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } on FirebaseException catch (e) {
        if (e.code == 'duplicate-app') {
          debugPrint('Firebase already initialized (native). Ignoring.');
        } else {
          rethrow;
        }
      }
    } else {
      debugPrint('Firebase already initialized (dart).');
    }
    debugPrint('Firebase initialized successfully.');

    // Silent anonymous auth at startup to avoid permission issues.
    // If it fails (e.g. the web origin is not yet authorized in Firebase),
    // log and continue so the UI still renders instead of a dead screen.
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        debugPrint('Firebase: Silent login at startup...');
        await FirebaseAuth.instance.signInAnonymously();
      }
    } catch (e) {
      debugPrint('Firebase: Anonymous sign-in failed (continuing without auth): $e');
    }

    runApp(const ProviderScope(child: MyApp()));
  } catch (e, stackTrace) {
    debugPrint('Error during startup: $e');
    debugPrint('Stack trace: $stackTrace');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SelectableText('Startup Error: $e\n\n$stackTrace'),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Housie Multiplayer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const HomeScreen(),
    );
  }
}
