import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import 'dashboard/dashboard_screen.dart';
import 'leads/leads_screen.dart';
import 'campaigns/campaigns_screen.dart';
import 'suggestions/suggestions_screen.dart';
import 'analytics/analytics_screen.dart';
import 'settings/settings_screen.dart';

final _tabProvider = StateProvider<int>((ref) => 0);

class AppShell extends ConsumerWidget {
  const AppShell({super.key});
  static const _screens = [
    DashboardScreen(), LeadsScreen(), CampaignsScreen(),
    SuggestionsScreen(), AnalyticsScreen(), SettingsScreen(),
  ];
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(_tabProvider);
    return Scaffold(
      body: IndexedStack(index: index, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: AppColors.bgSecondary,
            border: Border(top: BorderSide(color: AppColors.border)),
            boxShadow: [BoxShadow(color: Color(0x0C000000), blurRadius: 12, offset: Offset(0, -3))]),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) => ref.read(_tabProvider.notifier).state = i,
          backgroundColor: Colors.transparent, elevation: 0,
          selectedItemColor: AppColors.accentBlue,
          unselectedItemColor: AppColors.textDisabled,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.nunitoSans(fontSize: 10, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.nunitoSans(fontSize: 10),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline_rounded), activeIcon: Icon(Icons.people_rounded), label: 'Leads'),
            BottomNavigationBarItem(icon: Icon(Icons.campaign_outlined), activeIcon: Icon(Icons.campaign_rounded), label: 'Campaigns'),
            BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_outlined), activeIcon: Icon(Icons.auto_awesome), label: 'AI Suggest'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics_rounded), label: 'Analytics'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings_rounded), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
