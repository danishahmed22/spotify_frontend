import 'package:flutter/material.dart';
import 'package:music/splash_screen.dart';

import 'audio_player_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initAudioService();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        primarySwatch: Colors.deepOrange,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const SplashScreen(),
    );
  }
}
