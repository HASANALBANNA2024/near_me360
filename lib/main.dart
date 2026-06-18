import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:near_me360/providers/theme_provider.dart';
import 'package:provider/provider.dart';

// নতুন সার্ভিস এবং স্প্ল্যাশ স্ক্রিনের ইমপোর্ট
import 'services/init_service.dart';
import 'splash_screen.dart';

void main() async {
  // ফ্লাটার উইজেট বাইন্ডিং ইনিশিয়ালাইজ করা (async main ব্যবহারের জন্য বাধ্যতামূলক)
  WidgetsFlutterBinding.ensureInitialized();

  // অ্যাপের শুরুতে অফলাইন ইঞ্জিন স্টার্ট হবে (লোকেশন পারমিশন ও ওয়ান-টাইম ডাউনলোড)
  await InitService.initializeApp();

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

      // লাইট মোড থিম (Poppins ফন্টসহ)
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        primaryColor: const Color(0xFF3B82F6),
        cardColor: Colors.white,
        // পুরো অ্যাপের সব ফন্ট ডাইনামিকালি 'Poppins' করা হলো
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
      ),

      // ডার্ক মোড থিম (Poppins ফন্টসহ)
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF3B82F6),
        cardColor: const Color(0xFF1E293B),
        // ডার্ক মোডেও সব ফন্ট 'Poppins' করা হলো
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      ),
      home: const SplashScreen(),
    );
  }
}
