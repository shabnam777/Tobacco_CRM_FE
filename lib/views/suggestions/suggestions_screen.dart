import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/suggestion_provider.dart';
import '../../providers/leads_provider.dart';
import '../../models/suggestion_model.dart';
import '../../core/constants/app_colors.dart';

class SuggestionsScreen extends ConsumerStatefulWidget {
  const SuggestionsScreen({super.key});
  @override
  ConsumerState<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends ConsumerState<SuggestionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  static const _verdicts = ['All', 'Proceed', 'Hold', 'Revoke'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(suggestionProvider.notifier).loadSuggestions());
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(suggestionProvider);
    ref.listen(suggestionProvider, (prev, next) {
      if (next.error.isNotEmpty && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error),
          backgroundColor: AppColors.error,
          action: SnackBarAction(
            label: 'Dismiss', textColor: Colors.white,
            onPressed: () => ref.read(suggestionProvider.notifier).clearError(),
          ),
        ));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('AI Suggestions', style: GoogleFonts.syne(
              fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          Text('Groq  •  Cloudflare  •  Meta Llama', style: GoogleFonts.nunitoSans(
              fontSize: 10, color: AppColors.accentBlue, fontWeight: FontWeight.w600)),
        ]),
        actions: [
          if (state.proceedCount > 0)
            TextButton.icon(
              onPressed: _approveAll,
              icon: const Icon(Icons.done_all, size: 15, color: AppColors.verdictProceed),
              label: Text('Add All (${state.proceedCount})', style: GoogleFonts.nunitoSans(
                  fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.verdictProceed)),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted),
            onPressed: () => ref.read(suggestionProvider.notifier).loadSuggestions(),
          ),
        ],
      ),
      body: state.isSearching ? _searching(state) : Column(children: [
        _banner(state),
        _tabBar(state),
        Expanded(child: _tabViews(state)),
      ]),
      bottomNavigationBar: _discoverBtn(state),
    );
  }

  Widget _banner(SuggestionState s) {
    if (s.suggestions.isEmpty) return const SizedBox.shrink();
    return Container(
      color: AppColors.bgSecondary,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(children: [
        _chip('✅ ${s.proceedCount}', AppColors.verdictProceed),
        const SizedBox(width: 8),
        _chip('⏸ ${s.holdCount}', AppColors.verdictHold),
        const SizedBox(width: 8),
        _chip('❌ ${s.revokeCount}', AppColors.verdictRevoke),
        const Spacer(),
        Text('${s.suggestions.length} total', style: GoogleFonts.nunitoSans(
            fontSize: 11, color: AppColors.textMuted)),
      ]),
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25))),
    child: Text(label, style: GoogleFonts.nunitoSans(
        fontSize: 11, fontWeight: FontWeight.w700, color: color)),
  );

  Widget _tabBar(SuggestionState s) => Container(
    color: AppColors.bgSecondary,
    child: TabBar(
      controller: _tabs,
      onTap: (i) => ref.read(suggestionProvider.notifier).setFilter(_verdicts[i]),
      labelColor: AppColors.accentBlue,
      unselectedLabelColor: AppColors.textMuted,
      indicatorColor: AppColors.accentBlue,
      dividerColor: AppColors.border,
      labelStyle: GoogleFonts.nunitoSans(fontSize: 11, fontWeight: FontWeight.w700),
      tabs: [
        Tab(text: 'All (${s.suggestions.length})'),
        Tab(text: '✅ ${s.proceedCount}'),
        Tab(text: '⏸ ${s.holdCount}'),
        Tab(text: '❌ ${s.revokeCount}'),
      ],
    ),
  );

  Widget _tabViews(SuggestionState s) {
    if (s.suggestions.isEmpty) return _empty();
    return TabBarView(
      controller: _tabs,
      children: List.generate(4, (_) => _SuggestionList(
        suggestions: s.filtered,
        onApprove: _approve,
        onRevoke: _revoke,
        onRevalidate: (id) => ref.read(suggestionProvider.notifier).revalidateEntry(id),
      )),
    );
  }

  Widget _empty() => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 80, height: 80,
        decoration: BoxDecoration(color: AppColors.accentBlue.withOpacity(0.08), shape: BoxShape.circle),
        child: const Icon(Icons.travel_explore_rounded, size: 36, color: AppColors.accentBlue)),
      const SizedBox(height: 20),
      Text('No Suggestions Yet', style: GoogleFonts.syne(
          fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      Text('Tap "Discover New Importers" to search the UAE market using 3 AI models.',
          style: GoogleFonts.nunitoSans(fontSize: 13, color: AppColors.textMuted, height: 1.5),
          textAlign: TextAlign.center),
      const SizedBox(height: 20),
      _AiBadges(),
    ]),
  ));

  Widget _searching(SuggestionState s) => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Stack(alignment: Alignment.center, children: [
        SizedBox(width: 70, height: 70,
            child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.accentBlue)),
        const Icon(Icons.auto_awesome, size: 28, color: AppColors.accentBlue),
      ]),
      const SizedBox(height: 20),
      Text('AI Discovery Running', style: GoogleFonts.syne(
          fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      Text(s.statusMessage, style: GoogleFonts.nunitoSans(
          fontSize: 13, color: AppColors.textMuted), textAlign: TextAlign.center),
      const SizedBox(height: 20),
      _AiBadges(),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.bgInput, borderRadius: BorderRadius.circular(12)),
        child: Text(
          '🔵  Groq LLaMA 70B — discovering importers\n'
          '🟠  Cloudflare AI — cross-validating results\n'
          '🟣  Meta Llama — independent analysis\n'
          '⚡  Deduplicating against existing leads',
          style: GoogleFonts.nunitoSans(fontSize: 12, color: AppColors.textSecondary, height: 1.9)),
      ),
    ]),
  ));

  Widget _discoverBtn(SuggestionState s) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
    decoration: const BoxDecoration(color: AppColors.bgSecondary,
        border: Border(top: BorderSide(color: AppColors.border))),
    child: SizedBox(
      height: 52, width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: s.isSearching ? null
            : () => ref.read(suggestionProvider.notifier).discoverNewImporters(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentBlue, foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.accentBlue.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
        icon: s.isSearching
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.travel_explore_rounded, size: 20),
        label: Text(s.isSearching ? 'Analyzing...' : 'Discover New Importers',
            style: GoogleFonts.nunitoSans(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    ),
  );

  Future<void> _approve(String id) async {
    final ok = await ref.read(suggestionProvider.notifier).approveEntryWithRef(id, ref);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? '✅ Lead added to pipeline' : 'Failed to approve'),
      backgroundColor: ok ? AppColors.success : AppColors.error,
    ));
  }

  Future<void> _revoke(String id) async {
    await ref.read(suggestionProvider.notifier).revokeEntry(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry revoked')));
  }

  Future<void> _approveAll() async {
    final count = ref.read(suggestionProvider).proceedCount;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add All Proceed Leads',
            style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('Add all $count "Proceed" leads to pipeline?',
            style: GoogleFonts.nunitoSans(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add All')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final added = await ref.read(suggestionProvider.notifier).approveAllProceed(ref);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✅ $added leads added to pipeline'), backgroundColor: AppColors.success));
  }
}

class _SuggestionList extends StatelessWidget {
  final List<SuggestionModel> suggestions;
  final Function(String) onApprove, onRevoke, onRevalidate;
  const _SuggestionList({required this.suggestions, required this.onApprove,
      required this.onRevoke, required this.onRevalidate});

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return Center(child: Text('No leads in this category',
          style: GoogleFonts.nunitoSans(fontSize: 14, color: AppColors.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: suggestions.length,
      itemBuilder: (_, i) => _SuggestionCard(
        suggestion: suggestions[i],
        onApprove: () => onApprove(suggestions[i].id),
        onRevoke: () => onRevoke(suggestions[i].id),
        onRevalidate: () => onRevalidate(suggestions[i].id),
      ),
    );
  }
}

class _SuggestionCard extends StatefulWidget {
  final SuggestionModel suggestion;
  final VoidCallback onApprove, onRevoke, onRevalidate;
  const _SuggestionCard({required this.suggestion, required this.onApprove,
      required this.onRevoke, required this.onRevalidate});
  @override
  State<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<_SuggestionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.suggestion;
    final color = AppColors.getVerdictColor(s.finalVerdict);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25), width: 1.5),
          boxShadow: AppColors.cardShadow),
      child: Column(children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.25))),
                  child: Center(child: Text(s.initials, style: GoogleFonts.syne(
                      fontSize: 14, fontWeight: FontWeight.w800, color: color)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.companyName, style: GoogleFonts.syne(fontSize: 13,
                      fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (s.contactPerson?.isNotEmpty == true)
                    Text(s.contactPerson!, style: GoogleFonts.nunitoSans(
                        fontSize: 11, color: AppColors.accentBlue, fontWeight: FontWeight.w600)),
                  Text('${s.city ?? 'UAE'}  •  ${s.tradeType ?? 'Trading'}',
                      style: GoogleFonts.nunitoSans(fontSize: 11, color: AppColors.textMuted)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  _VerdictBadge(verdict: s.finalVerdict),
                  const SizedBox(height: 4),
                  Text('${s.combinedScore}/100', style: GoogleFonts.syne(
                      fontSize: 14, fontWeight: FontWeight.w800, color: color)),
                ]),
              ]),
              const SizedBox(height: 10),
              if (s.analysisDone)
                Row(children: [
                  _pill('G', s.groqScore, s.groqRecommendation, AppColors.groqColor),
                  const SizedBox(width: 6),
                  _pill('CF', s.cfScore, s.cfRecommendation, AppColors.cfColor),
                  const SizedBox(width: 6),
                  _pill('L', s.llamaScore, s.llamaRecommendation, AppColors.llamaColor),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Row(children: [
                      Text(_expanded ? 'Less' : 'Details', style: GoogleFonts.nunitoSans(
                          fontSize: 11, color: AppColors.accentBlue, fontWeight: FontWeight.w600)),
                      Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                          size: 16, color: AppColors.accentBlue),
                    ]),
                  ),
                ])
              else
                Text('Analysis pending...', style: GoogleFonts.nunitoSans(
                    fontSize: 11, color: AppColors.textMuted)),
            ]),
          ),
        ),
        if (_expanded) _buildDetail(s),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: widget.onRevoke,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.verdictRevoke,
                side: BorderSide(color: AppColors.verdictRevoke.withOpacity(0.4)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              icon: const Icon(Icons.cancel_outlined, size: 15),
              label: Text('Revoke', style: GoogleFonts.nunitoSans(fontSize: 13, fontWeight: FontWeight.w700)),
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onRevalidate,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.bgInput,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border)),
                child: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textMuted)),
            ),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: ElevatedButton.icon(
              onPressed: widget.onApprove,
              style: ElevatedButton.styleFrom(
                backgroundColor: s.finalVerdict == 'Revoke'
                    ? AppColors.textDisabled : AppColors.verdictProceed,
                foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              icon: const Icon(Icons.add_circle_outline, size: 15),
              label: Text('Add to Pipeline', style: GoogleFonts.nunitoSans(
                  fontSize: 13, fontWeight: FontWeight.w700)),
            )),
          ]),
        ),
      ]),
    );
  }

  Widget _pill(String lbl, int score, String rec, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.2))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(lbl, style: GoogleFonts.syne(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(width: 3),
      Text('$score', style: GoogleFonts.syne(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    ]),
  );

  Widget _buildDetail(SuggestionModel s) => Container(
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.bgPrimary, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (s.email.isNotEmpty) _row(Icons.email_outlined, s.email),
      if (s.phone?.isNotEmpty == true) _row(Icons.phone_outlined, s.phone!),
      if (s.website?.isNotEmpty == true) _row(Icons.language_outlined, s.website!),
      if (s.annualTurnover?.isNotEmpty == true) _row(Icons.attach_money, s.annualTurnover!),
      const Divider(height: 14, color: AppColors.border),
      _aiBlock('🔵 Groq', s.groqScore, s.groqAnalysis, s.groqRecommendation, AppColors.groqColor),
      const SizedBox(height: 8),
      _aiBlock('🟠 Cloudflare', s.cfScore, s.cfAnalysis, s.cfRecommendation, AppColors.cfColor),
      const SizedBox(height: 8),
      _aiBlock('🟣 Meta Llama', s.llamaScore, s.llamaAnalysis, s.llamaRecommendation, AppColors.llamaColor),
      if (s.combinedInsight.isNotEmpty) ...[
        const Divider(height: 14, color: AppColors.border),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.accentBlue.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('💡 Combined Insight', style: GoogleFonts.nunitoSans(
                fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accentBlue)),
            const SizedBox(height: 4),
            Text(s.combinedInsight, style: GoogleFonts.nunitoSans(
                fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
          ]),
        ),
      ],
      if (s.suggestedAction.isNotEmpty) ...[
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.arrow_forward_ios, size: 11, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Expanded(child: Text(s.suggestedAction, style: GoogleFonts.nunitoSans(
              fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic))),
        ]),
      ],
      if (s.riskFlags.isNotEmpty) ...[
        const SizedBox(height: 8),
        Wrap(spacing: 6, children: s.riskFlags.map((f) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6)),
          child: Text('⚠ $f', style: GoogleFonts.nunitoSans(
              fontSize: 10, color: AppColors.error, fontWeight: FontWeight.w600)),
        )).toList()),
      ],
    ]),
  );

  Widget _row(IconData icon, String val) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(children: [
      Icon(icon, size: 13, color: AppColors.textMuted), const SizedBox(width: 6),
      Expanded(child: Text(val, style: GoogleFonts.nunitoSans(
          fontSize: 12, color: AppColors.textSecondary),
          maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]),
  );

  Widget _aiBlock(String prov, int score, String analysis, String rec, Color color) {
    final rc = AppColors.getVerdictColor(rec);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 36, height: 36,
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Center(child: Text('$score', style: GoogleFonts.syne(
            fontSize: 13, fontWeight: FontWeight.w800, color: color)))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(prov, style: GoogleFonts.nunitoSans(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: rc.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
            child: Text(rec.isNotEmpty ? rec : 'Hold', style: GoogleFonts.nunitoSans(
                fontSize: 9, fontWeight: FontWeight.w700, color: rc))),
        ]),
        const SizedBox(height: 2),
        Text(analysis.isNotEmpty ? analysis : 'Analysis not available',
            style: GoogleFonts.nunitoSans(fontSize: 11, color: AppColors.textMuted, height: 1.4),
            maxLines: 3, overflow: TextOverflow.ellipsis),
      ])),
    ]);
  }
}

class _VerdictBadge extends StatelessWidget {
  final String verdict;
  const _VerdictBadge({required this.verdict});
  @override
  Widget build(BuildContext context) {
    final color = AppColors.getVerdictColor(verdict);
    final icon = verdict == 'Proceed' ? '✅' : verdict == 'Revoke' ? '❌' : '⏸';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Text('$icon $verdict', style: GoogleFonts.nunitoSans(
          fontSize: 10, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

class _AiBadges extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    _b('Groq', AppColors.groqColor), const SizedBox(width: 8),
    _b('Cloudflare', AppColors.cfColor), const SizedBox(width: 8),
    _b('Meta Llama', AppColors.llamaColor),
  ]);
  Widget _b(String l, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: c.withOpacity(0.09), borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withOpacity(0.25))),
    child: Text(l, style: GoogleFonts.nunitoSans(fontSize: 11, fontWeight: FontWeight.w700, color: c)),
  );
}
