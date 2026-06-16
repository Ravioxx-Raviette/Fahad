import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed to fix status bar color
import 'screens/upload_screen_simple.dart';
import 'screens/result_screen.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
// import 'screens/report_screen.dart'; // Uncomment if you have this file

void main() {
  // Ensure the status bar (battery/wifi icons) looks good on black
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light, // White icons
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FAHAD Deepfake Detector',

      // --- THE FIX IS HERE ---
      // We set the global theme to Dark so transitions are black, not white.
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.black,
        canvasColor: Colors.black, // Fixes white flash in some transitions
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        useMaterial3: true,
      ),
      // -----------------------

      initialRoute: '/home',
      routes: {
        '/home': (context) => const HomeScreen(),
        '/upload': (context) => const UploadScreenSimple(),
        '/result': (context) => const ResultScreen(),
        '/history': (context) => const HistoryScreen(),
        // '/report': (context) => const ReportScreen(), // Uncomment if needed
      },
    );
  }
}
