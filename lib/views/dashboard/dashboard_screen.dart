import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/leads_provider.dart';
import '../../providers/campaign_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/suggestion_provider.dart';
import '../../core/constants/app_colors.dart';
import '../leads/lead_detail_screen.dart';
import '../leads/add_edit_lead_screen.dart';
import '../suggestions/suggestions_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(leadsProvider.notifier).loadLeads();
      ref.read(campaignProvider.notifier).loadCampaigns();
      ref.read(analyticsProvider.notifier).loadAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: RefreshIndicator(
        color: AppColors.accentBlue,
        onRefresh: _refresh,
        child: CustomScrollView(slivers: [
          _appBar(),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(delegate: SliverChildListDelegate([
              _statsGrid(),
              const SizedBox(height: 16),
              _aiBanner(),
              const SizedBox(height: 16),
              _activityChart(),
              const SizedBox(height: 16),
              _followupAlert(),
              _pipeline(),
              const SizedBox(height: 16),
              _recentLeads(),
              const SizedBox(height: 100),
            ])),
          ),
        ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddEditLeadScreen())),
        backgroundColor: AppColors.accentBlue, foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Add Lead', style: GoogleFonts.nunitoSans(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(leadsProvider.notifier).loadLeads(),
      ref.read(analyticsProvider.notifier).loadAnalytics(),
    ]);
  }

  SliverAppBar _appBar() {
    return SliverAppBar(
      floating: true, snap: true,
      backgroundColor: AppColors.bgSecondary, surfaceTintColor: Colors.transparent,
      title: Row(children: [
        Container(width: 32, height: 32,
          decoration: BoxDecoration(gradient: AppColors.blueGradient,
              borderRadius: BorderRadius.circular(9)),
          child: Center(child: Text('T', style: GoogleFonts.syne(
              fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)))),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('TobaccoCRM', style: GoogleFonts.syne(
              fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          Text('UAE Export Intelligence', style: GoogleFonts.nunitoSans(
              fontSize: 10, color: AppColors.accentBlue, fontWeight: FontWeight.w600)),
        ]),
      ]),
      actions: [
        Consumer(builder: (_, ref, __) {
          final count = ref.watch(leadCountProvider);
          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accentBlue.withOpacity(0.2))),
            child: Text('$count leads', style: GoogleFonts.nunitoSans(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accentBlue)));
        }),
      ],
    );
  }

  Widget _statsGrid() {
    return Consumer(builder: (_, ref, __) {
      final l = ref.watch(leadsProvider);
      final c = ref.watch(campaignProvider);
      final items = [
        ('Total Leads',    '${l.totalCount}',      Icons.people_outline_rounded, AppColors.accentBlue,   '${l.newCount} new'),
        ('Emails Sent',    '${c.totalSent}',        Icons.send_outlined,          AppColors.accentGold,   'This month'),
        ('Interested',     '${l.interestedCount}',  Icons.star_outline_rounded,   AppColors.success,      '${l.closedCount} closed'),
        ('Followups Due',  '${l.followupCount}',    Icons.schedule_outlined,      AppColors.warning,
            l.followupCount > 0 ? 'Action needed' : 'All clear ✓'),
      ];
      return GridView.count(
        crossAxisCount: 2, childAspectRatio: 1.4,
        crossAxisSpacing: 10, mainAxisSpacing: 10,
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        children: items.map((s) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.cardShadow),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: s.$4.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9)),
              child: Icon(s.$3, color: s.$4, size: 18)),
            const SizedBox(height: 10),
            Text(s.$2, style: GoogleFonts.syne(fontSize: 24,
                fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1)),
            const SizedBox(height: 3),
            Text(s.$1, style: GoogleFonts.nunitoSans(fontSize: 12,
                color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            Text(s.$5, style: GoogleFonts.nunitoSans(fontSize: 10, color: AppColors.textMuted)),
          ]),
        )).toList(),
      );
    });
  }

  Widget _aiBanner() {
    return Consumer(builder: (_, ref, __) {
      final s = ref.watch(suggestionProvider);
      if (s.suggestions.isEmpty && s.error.isEmpty) return const SizedBox.shrink();
      final count = s.proceedCount;
      return GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SuggestionsScreen())),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(gradient: AppColors.blueGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.accentBlue.withOpacity(0.25),
                  blurRadius: 12, offset: const Offset(0, 4))]),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(count > 0
                  ? '$count AI-Verified Importers Ready'
                  : '${s.suggestions.length} AI Suggestions Pending',
                  style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              Text('Groq  •  Cloudflare  •  Meta Llama',
                  style: GoogleFonts.nunitoSans(fontSize: 11, color: Colors.white70)),
            ])),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white70),
          ]),
        ),
      );
    });
  }

  Widget _activityChart() {
    return Consumer(builder: (_, ref, __) {
      final activity = ref.watch(analyticsProvider).weeklyActivity;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.cardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Outreach Activity', style: GoogleFonts.syne(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text('Last 7 days', style: GoogleFonts.nunitoSans(
                  fontSize: 11, color: AppColors.textMuted)),
            ]),
            Row(children: [
              _legend('Emails', AppColors.accentBlue),
              const SizedBox(width: 10),
              _legend('Leads', AppColors.accentTeal),
            ]),
          ]),
          const SizedBox(height: 14),
          SizedBox(height: 110,
            child: activity.isEmpty
                ? Center(child: Text('No activity yet',
                    style: GoogleFonts.nunitoSans(fontSize: 12, color: AppColors.textMuted)))
                : LineChart(LineChartData(
                    gridData: FlGridData(show: true, drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: AppColors.border, strokeWidth: 1, dashArray: [4, 4])),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true, reservedSize: 20,
                        getTitlesWidget: (v, _) {
                          const d = ['M','T','W','T','F','S','S'];
                          final i = v.toInt();
                          if (i < 0 || i >= d.length) return const SizedBox();
                          return Text(d[i], style: GoogleFonts.nunitoSans(
                              fontSize: 10, color: AppColors.textMuted));
                        },
                      )),
                    ),
                    borderData: FlBorderData(show: false),
                    lineTouchData: LineTouchData(touchTooltipData:
                        LineTouchTooltipData(getTooltipColor: (_) => AppColors.bgCard)),
                    lineBarsData: [
                      _lineBar(activity.asMap().entries.map((e) =>
                          FlSpot(e.key.toDouble(), e.value.emailsSent.toDouble())).toList(),
                          AppColors.accentBlue),
                      _lineBar(activity.asMap().entries.map((e) =>
                          FlSpot(e.key.toDouble(), e.value.leadsAdded.toDouble())).toList(),
                          AppColors.accentTeal),
                    ],
                  )),
          ),
        ]),
      );
    });
  }

  LineChartBarData _lineBar(List<FlSpot> spots, Color color) => LineChartBarData(
    spots: spots, isCurved: true, color: color, barWidth: 2.5,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(show: true,
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [color.withOpacity(0.15), color.withOpacity(0)])),
  );

  Widget _legend(String label, Color color) => Row(children: [
    Container(width: 12, height: 3,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 4),
    Text(label, style: GoogleFonts.nunitoSans(fontSize: 11, color: AppColors.textMuted)),
  ]);

  Widget _followupAlert() {
    return Consumer(builder: (_, ref, __) {
      final due = ref.watch(followupsDueProvider);
      if (due.isEmpty) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withOpacity(0.3))),
        child: Row(children: [
          const Icon(Icons.schedule_outlined, color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${due.length} Followup${due.length > 1 ? 's' : ''} Due',
                style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.warning)),
            Text(due.take(2).map((l) => l.companyName).join(', '),
                style: GoogleFonts.nunitoSans(fontSize: 11, color: AppColors.textSecondary)),
          ])),
          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.warning),
        ]),
      );
    });
  }

  Widget _pipeline() {
    return Consumer(builder: (_, ref, __) {
      final l = ref.watch(leadsProvider);
      if (l.totalCount == 0) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.cardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Pipeline', style: GoogleFonts.syne(fontSize: 14,
              fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          ClipRRect(borderRadius: BorderRadius.circular(6),
            child: SizedBox(height: 10, child: Row(children: [
              _bar(l.newCount, l.totalCount, AppColors.statusNew),
              _bar(l.contactedCount, l.totalCount, AppColors.statusContacted),
              _bar(l.followupCount, l.totalCount, AppColors.statusFollowup),
              _bar(l.repliedCount, l.totalCount, AppColors.statusReplied),
              _bar(l.interestedCount, l.totalCount, AppColors.statusInterested),
              _bar(l.closedCount, l.totalCount, AppColors.statusClosed),
            ]))),
          const SizedBox(height: 10),
          Wrap(spacing: 10, runSpacing: 6, children: [
            _leg('New', l.newCount, AppColors.statusNew),
            _leg('Contacted', l.contactedCount, AppColors.statusContacted),
            _leg('Followup', l.followupCount, AppColors.statusFollowup),
            _leg('Replied', l.repliedCount, AppColors.statusReplied),
            _leg('Interested', l.interestedCount, AppColors.statusInterested),
            _leg('Closed', l.closedCount, AppColors.statusClosed),
          ]),
        ]),
      );
    });
  }

  Widget _bar(int n, int total, Color c) {
    if (n == 0 || total == 0) return const SizedBox.shrink();
    return Flexible(flex: n, child: Container(color: c));
  }

  Widget _leg(String l, int n, Color c) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text('$l ($n)', style: GoogleFonts.nunitoSans(fontSize: 11, color: AppColors.textSecondary)),
  ]);

  Widget _recentLeads() {
    return Consumer(builder: (_, ref, __) {
      final leads = ref.watch(leadsProvider).leads.take(4).toList();
      if (leads.isEmpty) return const SizedBox.shrink();
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Recent Leads', style: GoogleFonts.syne(
              fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text('See All', style: GoogleFonts.nunitoSans(
              fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accentBlue)),
        ]),
        const SizedBox(height: 10),
        ...leads.map((lead) => GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => LeadDetailScreen(leadId: lead.id))),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.cardShadow),
            child: Row(children: [
              Container(width: 38, height: 38,
                decoration: BoxDecoration(
                  color: AppColors.getStatusColor(lead.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(lead.initials, style: GoogleFonts.syne(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.getStatusColor(lead.status))))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(lead.companyName, style: GoogleFonts.syne(
                    fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(lead.email, style: GoogleFonts.nunitoSans(
                    fontSize: 11, color: AppColors.textMuted),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.getStatusColor(lead.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
                child: Text(lead.status, style: GoogleFonts.nunitoSans(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: AppColors.getStatusColor(lead.status)))),
            ]),
          ),
        )),
      ]);
    });
  }
}
