import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:near_me360/providers/theme_provider.dart';
import 'package:provider/provider.dart';

import '../providers/home_provider.dart';
// নতুন সার্ভিস এবং স্প্ল্যাশ স্ক্রিনের ইমপোর্ট
import 'services/init_service.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // অ্যাপের শুরুতে অফলাইন ENGINE স্টার্ট হবে
  await InitService.initializeApp();

  runApp(
    // 💡 MultiProvider দিয়ে দুটি প্রোভাইডারকেই রেজিস্টার করা হলো
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => HomeProvider()..loadCachedData(),
        ), // ✅ এটি যোগ হলো
      ],
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

      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        primaryColor: const Color(0xFF3B82F6),
        cardColor: Colors.white,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF3B82F6),
        cardColor: const Color(0xFF1E293B),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      ),
      home: const SplashScreen(),
    );
  }
}
