import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'admin@tobaccocrm.in');
  final _passCtrl  = TextEditingController(text: 'password123');
  bool _obscure = true;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          const SizedBox(height: 60),
          Container(width: 76, height: 76,
            decoration: BoxDecoration(gradient: AppColors.blueGradient, borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: AppColors.accentBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]),
            child: Center(child: Text('T', style: GoogleFonts.syne(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white)))),
          const SizedBox(height: 20),
          Text('TobaccoCRM', style: GoogleFonts.syne(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('UAE Export Intelligence Platform', style: GoogleFonts.nunitoSans(fontSize: 13, color: AppColors.accentBlue, fontWeight: FontWeight.w600)),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border), boxShadow: AppColors.elevatedShadow),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Sign In', style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 20),
              TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.nunitoSans(fontSize: 14, color: AppColors.textPrimary),
                decoration: _dec('Email', Icons.email_outlined)),
              const SizedBox(height: 12),
              TextField(controller: _passCtrl, obscureText: _obscure, onSubmitted: (_) => _login(),
                style: GoogleFonts.nunitoSans(fontSize: 14, color: AppColors.textPrimary),
                decoration: _dec('Password', Icons.lock_outline).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.textMuted, size: 18),
                    onPressed: () => setState(() => _obscure = !_obscure)))),
            ])),
          if (auth.error.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.error.withOpacity(0.3))),
              child: Row(children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 16), const SizedBox(width: 8),
                Expanded(child: Text(auth.error, style: GoogleFonts.nunitoSans(fontSize: 13, color: AppColors.error))),
                GestureDetector(onTap: () => ref.read(authProvider.notifier).clearError(),
                  child: const Icon(Icons.close, color: AppColors.error, size: 16)),
              ])),
          ],
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : _login,
              style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: auth.isLoading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Sign In', style: GoogleFonts.nunitoSans(fontSize: 16, fontWeight: FontWeight.w700)))),
          const SizedBox(height: 12),
          Row(children: [
            const Expanded(child: Divider(color: AppColors.border)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or', style: GoogleFonts.nunitoSans(fontSize: 13, color: AppColors.textMuted))),
            const Expanded(child: Divider(color: AppColors.border)),
          ]),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, height: 50,
            child: OutlinedButton.icon(
              onPressed: () => ref.read(authProvider.notifier).loginOffline(),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.accentTeal,
                side: const BorderSide(color: AppColors.accentTeal),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              icon: const Icon(Icons.offline_bolt_outlined, size: 18),
              label: Text('Continue Offline (Demo Data)', style: GoogleFonts.nunitoSans(fontSize: 14, fontWeight: FontWeight.w700)))),
          const SizedBox(height: 20),
          Text('Default: admin@tobaccocrm.in / password123',
            style: GoogleFonts.nunitoSans(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 20),
        ]),
      )),
    );
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: AppColors.textMuted, size: 18),
    filled: true, fillColor: AppColors.bgInput,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accentBlue, width: 2)),
    labelStyle: GoogleFonts.nunitoSans(fontSize: 13, color: AppColors.textMuted),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14));

  Future<void> _login() async {
    ref.read(authProvider.notifier).clearError();
    await ref.read(authProvider.notifier).login(_emailCtrl.text.trim(), _passCtrl.text.trim());
  }
}
