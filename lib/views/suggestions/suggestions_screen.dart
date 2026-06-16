import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../models/suggestion_model.dart';
import '../../providers/suggestion_provider.dart';

class SuggestionsScreen extends ConsumerStatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  ConsumerState<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends ConsumerState<SuggestionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  final tabs = const ['All', 'Proceed', 'Hold', 'Revoke'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(suggestionProvider.notifier).loadSuggestions(),
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(suggestionProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,

      // ================= APP BAR =================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.bgSecondary,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AI Suggestions Engine",
                  style: GoogleFonts.syne(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  "Groq • Cloudflare • Llama",
                  style: GoogleFonts.nunitoSans(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            _cta(state)
          ],
        ),
        actions: [
          if (state.proceedCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _approveAll,
                icon: const Icon(
                  Icons.done_all,
                  size: 18,
                  color: AppColors.verdictProceed,
                ),
                label: Text(
                  "Add All (${state.proceedCount})",
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.verdictProceed,
                  ),
                ),
              ),
            ),
        ],
      ),

      // ================= BODY =================
      body: Column(
        children: [
          _topMetrics(state),
          _tabBar(state),
          Expanded(child: _list(state)),
        ],
      ),
    );
  }

  // ================= TOP METRICS =================
  Widget _topMetrics(SuggestionState s) {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _metric("Proceed", s.proceedCount, AppColors.verdictProceed),
          _metric("Hold", s.holdCount, AppColors.verdictHold),
        ],
      ),
    );
  }

  Future<void> _approveAll() async {
    final notifier = ref.read(suggestionProvider.notifier);
    final state = ref.read(suggestionProvider);

    final count = state.proceedCount;
    if (count == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: const Text("Confirm Bulk Approval"),
        content: Text("Add $count leads to pipeline?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // 🔥 SHOW LOADING STATE (important fix)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final added = await notifier.approveAllProceed(ref);

      if (!mounted) return;

      Navigator.pop(context); // close loader ONLY after completion

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ $added leads added to pipeline"),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Bulk approval failed"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _metric(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          "$value",
          style: GoogleFonts.syne(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.nunitoSans(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  // ================= TAB BAR =================
  Widget _tabBar(SuggestionState s) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        onTap: (i) {
          final filter = tabs[i];
          ref.read(suggestionProvider.notifier).setFilter(filter);
          _tabs.animateTo(i); // 🔥 IMPORTANT FIX
        },
        controller: _tabs,
        indicator: BoxDecoration(
          color: AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: AppColors.accentBlue,
        unselectedLabelColor: AppColors.textMuted,
        dividerColor: Colors.transparent,
        dragStartBehavior: DragStartBehavior.down,
        tabs: [
          Tab(text: "All (${s.suggestions.length})"),
          Tab(text: "Proceed (${s.proceedCount})"),
          Tab(text: "Hold (${s.holdCount})"),
          // Tab(text: "Revoke (${s.revokedSuggestions.length})"),
        ],
      ),
    );
  }

  // ================= GRID LIST (2 per row) =================
  Widget _list(SuggestionState s) {
    if (s.suggestions.isEmpty) {
      return const Center(
        child: Text(
          "No suggestions found",
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;

        final width = constraints.maxWidth;

        if (width < 600) {
          crossAxisCount = 2; // mobile
        } else if (width < 1000) {
          crossAxisCount = 3; // tablet
        } else {
          crossAxisCount = 4; // desktop / large screens
        }

        return GridView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: s.filtered.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,

            // 🔥 important fix for overflow prevention
            childAspectRatio: _getAspectRatio(crossAxisCount),
          ),
          itemBuilder: (_, i) => _card(s.filtered[i]),
        );
      },
    );
  }

  double _getAspectRatio(int crossAxisCount) {
    switch (crossAxisCount) {
      case 2:
        return 1.3; // tall cards for mobile
      case 3:
        return 1.4; // balanced
      case 4:
        return 1.6; // compact desktop
      default:
        return 1.6;
    }
  }

  // ================= PREMIUM CARD =================
  Widget _card(SuggestionModel s) {
    final color = AppColors.getVerdictColor(s.finalVerdict);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            children: [
              Expanded(
                child: Text(
                  s.companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.syne(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _badge(s.finalVerdict, color),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            "${s.city ?? 'UAE'} • ${s.tradeType ?? 'Trading'}",
            style: GoogleFonts.nunitoSans(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),

          const SizedBox(height: 10),

          // SCORE
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bgInput,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Score", style: TextStyle(color: AppColors.textSecondary)),
                Text(
                  "${s.combinedScore}/100",
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // ACTIONS
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ref.read(suggestionProvider.notifier).revokeEntry(s.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.verdictRevoke,
                    side: const BorderSide(color: AppColors.verdictRevoke),
                  ),
                  child: const Text("Delete", style: TextStyle(color: AppColors.verdictRevoke)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => ref.read(suggestionProvider.notifier).approveEntryWithRef(s.id, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.verdictHold,
                  ),
                  child: const Text("Add"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ================= CTA =================
  Widget _cta(SuggestionState s) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: ElevatedButton.icon(
        onPressed: s.isSearching ? null : () => ref.read(suggestionProvider.notifier).discoverNewImporters(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentBlue,
          padding: const EdgeInsets.all(14),
        ),
        icon: s.isSearching
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(
          s.isSearching ? "Analyzing..." : "Discover New Importers",
        ),
      ),
    );
  }
}
