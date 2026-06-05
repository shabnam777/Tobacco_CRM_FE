import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/app_colors.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/leads_provider.dart';
import 'providers/suggestion_provider.dart';
import 'views/app_shell.dart';
import 'views/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.bgSecondary,
      systemNavigationBarIconBrightness: Brightness.dark));
  await StorageService.init();
  runApp(const ProviderScope(child: TobaccoCRMApp()));
}

class TobaccoCRMApp extends StatelessWidget {
  const TobaccoCRMApp({super.key});
  @override
  Widget build(BuildContext context) =>
      MaterialApp(title: 'TobaccoCRM', debugShowCheckedModeBanner: false, theme: AppTheme.lightTheme, home: const _AuthGate());
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return switch (auth.status) {
      AuthStatus.authenticated => const _AppRoot(),
      AuthStatus.initial || AuthStatus.loading => const _Splash(),
      _ => const LoginScreen(),
    };
  }
}

class _AppRoot extends ConsumerStatefulWidget {
  const _AppRoot();
  @override
  ConsumerState<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<_AppRoot> {
  bool _ready = false;
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  Future<void> _init() async {
    await ref.read(leadsProvider.notifier).loadLeads();

    if (ref.read(leadsProvider).leads.isEmpty) {
      try {
        final raw = await rootBundle.loadString('assets/data/importers.json');
        ref.read(leadsProvider.notifier).loadFromPreloaded(jsonDecode(raw) as List);
      } catch (_) {}
    }

    if (!StorageService.isOfflineMode) {
      ref.read(suggestionProvider.notifier).loadSuggestions().catchError((_) {});
    }

    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) => _ready ? const AppShell() : const _Splash();
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bgSecondary,
        body: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  gradient: AppColors.blueGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: AppColors.accentBlue.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 8))]),
              child: Center(child: Text('T', style: GoogleFonts.syne(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white)))),
          const SizedBox(height: 20),
          Text('TobaccoCRM', style: GoogleFonts.syne(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('UAE Export Intelligence', style: GoogleFonts.nunitoSans(fontSize: 13, color: AppColors.accentBlue, fontWeight: FontWeight.w600)),
          const SizedBox(height: 40),
          const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: AppColors.accentBlue, strokeWidth: 2.5)),
        ])),
      );
}
