import 'package:flutter/material.dart';

import 'screens/education_content.dart';
import 'screens/emergency_content.dart';
// স্ক্রিনগুলোর ইমপোর্ট
import 'screens/home_content.dart';
import 'screens/transport_content.dart';
// উইজেটগুলোর ইমপোর্ট
import 'widgets/bottom_navigation.dart';
import 'widgets/responsive_builder.dart';
import 'widgets/sidebar_navigation.dart';
import 'widgets/top_header.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _bodyContents = const [
    HomeContent(),
    EmergencyContent(),
    EducationContent(),
    TransportContent(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // মোবাইল ভিউর জন্য বটম বার
      bottomNavigationBar: ResponsiveBuilder(
        mobile: BottomNavigation(
          currentIndex: _currentIndex,
          onIndexChanged: (index) => setState(() => _currentIndex = index),
        ),
        desktop: const SizedBox.shrink(),
      ),
      body: ResponsiveBuilder(
        // ১. মোবাইল এবং ট্যাবলেট লেআউট (যা একদম পারফেক্ট থাকবে ফুল স্ক্রিন জুড়ে)
        mobile: SafeArea(
          child: Column(
            children: [
              const Padding(padding: EdgeInsets.all(16.0), child: TopHeader()),
              Expanded(child: _bodyContents[_currentIndex]),
            ],
          ),
        ),

        // ২. ওয়েব এবং ডেস্কটপ লেআউট (যা ১১০০ পিক্সেলের ওপরে আর ছড়াবে না)
        desktop: Row(
          children: [
            // সাইডবার বাম পাশেই ফিক্সড থাকবে আপনার ইমেজের মতো
            SidebarNavigation(
              currentIndex: _currentIndex,
              onIndexChanged: (index) => setState(() => _currentIndex = index),
            ),

            // ডান পাশের মূল কনটেন্ট এরিয়াকে আমরা মাঝখানে এনে ১১০০ পিক্সেল লক করব
            Expanded(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                alignment: Alignment.topCenter, // কনটেন্টকে মাঝখানে এলাইন করবে
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth:
                        1100, // আপনার রিকোয়েস্ট অনুযায়ী সর্বোচ্চ ১১০০ পিক্সেল উইডথ লক করা হলো
                  ),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 20.0,
                        ),
                        child: TopHeader(),
                      ),
                      Expanded(child: _bodyContents[_currentIndex]),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
