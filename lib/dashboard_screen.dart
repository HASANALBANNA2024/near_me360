import 'package:flutter/material.dart';

import 'screens/education_content.dart';
import 'screens/emergency_content.dart';
import 'screens/home_content.dart';
import 'screens/transport_content.dart';
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

      bottomNavigationBar: ResponsiveBuilder(
        mobile: BottomNavigation(
          currentIndex: _currentIndex,
          onIndexChanged: (index) => setState(() => _currentIndex = index),
        ),
        desktop: const SizedBox.shrink(),
      ),
      body: ResponsiveBuilder(
        mobile: SafeArea(
          child: Column(
            children: [
              const Padding(padding: EdgeInsets.all(16.0), child: TopHeader()),
              Expanded(child: _bodyContents[_currentIndex]),
            ],
          ),
        ),

        desktop: Row(
          children: [
            SidebarNavigation(
              currentIndex: _currentIndex,
              onIndexChanged: (index) => setState(() => _currentIndex = index),
            ),

            Expanded(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
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
