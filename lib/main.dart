import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // ১. গুগলের ডাইনামিক ফন্ট প্যাকেজ ইমপোর্ট করা হলো
import 'package:near_me360/providers/theme_provider.dart';
import 'package:provider/provider.dart';

import 'splash_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const NearMeApp(),
    ),
  );
}

class NearMeApp extends StatelessWidget {
  const NearMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'NearMe Finder',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      /// light mode
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        primaryColor: const Color(0xFF3B82F6),
        cardColor: Colors.white,

        /// full app content fonts
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      ),

      /// dark mode font and dark mode setup
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF3B82F6),
        cardColor: const Color(0xFF1E293B),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      home: const SplashScreen(),
    );
  }
}
