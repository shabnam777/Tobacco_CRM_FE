import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/campaign_provider.dart';
import '../../providers/leads_provider.dart';

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
        child: CustomScrollView(
          slivers: [
            _topBar(),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _kpiRow(),
                  const SizedBox(height: 12),
                  _aiBanner(),
                  const SizedBox(height: 12),
                  _activityCard(),
                  const SizedBox(height: 12),
                  _pipelineCard(),
                  const SizedBox(height: 12),
                  _followupCard(),
                  const SizedBox(height: 12),
                  _recentLeadsCard(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(leadsProvider.notifier).loadLeads(),
      ref.read(analyticsProvider.notifier).loadAnalytics(),
    ]);
  }

  // =========================
  // TOP BAR (SaaS HEADER)
  // =========================
  SliverAppBar _topBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppColors.bgSecondary,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: AppColors.blueGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'T',
                style: GoogleFonts.syne(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TobaccoCRM',
                style: GoogleFonts.syne(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'SaaS Dashboard',
                style: GoogleFonts.nunitoSans(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================
  // KPI ROW (HORIZONTAL STRIP)
  // =========================
  Widget _kpiRow() {
    return Consumer(builder: (_, ref, __) {
      final l = ref.watch(leadsProvider);
      final c = ref.watch(campaignProvider);

      final items = [
        ('Leads', '${l.totalCount}', Icons.people_outline, AppColors.accentBlue),
        ('Emails', '${c.totalSent}', Icons.send_outlined, AppColors.accentGold),
        ('Hot', '${l.interestedCount}', Icons.local_fire_department, AppColors.success),
        ('Followups', '${l.followupCount}', Icons.schedule_outlined, AppColors.warning),
      ];

      return SizedBox(
        height: 100,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;

            final double cardWidth = isWide ? (constraints.maxWidth / 4) - 12 : 150; // mobile horizontal scroll

            return ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final s = items[i];

                return Container(
                  width: cardWidth,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: s.$4.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(s.$3, size: 26, color: s.$4),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              s.$2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.syne(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              s.$1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunitoSans(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      );
    });
  }

  // =========================
  // AI BANNER (COMPACT)
  // =========================
  Widget _aiBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: AppColors.blueGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'AI Importer Discovery Active',
              style: GoogleFonts.syne(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white70),
        ],
      ),
    );
  }

  // =========================
  // ACTIVITY CARD (CHART)
  // =========================
  Widget _activityCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity',
            style: GoogleFonts.syne(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(height: 120, child: _buildChart()),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final activity = ref.watch(analyticsProvider).weeklyActivity;

    if (activity.isEmpty) {
      return Center(
        child: Text(
          'No Data',
          style: GoogleFonts.nunitoSans(fontSize: 11, color: AppColors.textMuted),
        ),
      );
    }

    return LineChart(
      LineChartData(
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineBarsData: [
          _line(activity, (e) => e.emailsSent.toDouble(), AppColors.accentBlue),
          _line(activity, (e) => e.leadsAdded.toDouble(), AppColors.accentTeal),
        ],
      ),
    );
  }

  LineChartBarData _line(
    List data,
    double Function(dynamic) fn,
    Color c,
  ) {
    return LineChartBarData(
      spots: List.generate(
        data.length,
        (i) => FlSpot(i.toDouble(), fn(data[i])),
      ),
      isCurved: true,
      color: c,
      barWidth: 2,
      dotData: const FlDotData(show: false),
    );
  }

  // =========================
  // PIPELINE CARD
  // =========================
  Widget _pipelineCard() {
    final l = ref.watch(leadsProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pipeline', style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              _pill('New', l.newCount, AppColors.statusNew),
              _pill('Hot', l.interestedCount, AppColors.success),
              _pill('Closed', l.closedCount, AppColors.accentGold),
            ],
          )
        ],
      ),
    );
  }

  Widget _pill(String t, int v, Color c) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$t $v', style: TextStyle(color: c, fontSize: 11)),
    );
  }

  // =========================
  // FOLLOWUPS CARD
  // =========================
  Widget _followupCard() {
    final due = ref.watch(followupsDueProvider);

    if (due.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${due.length} followups due',
        style: GoogleFonts.nunitoSans(fontSize: 12),
      ),
    );
  }

  // =========================
  // RECENT LEADS
  // =========================
  Widget _recentLeadsCard() {
    final leads = ref.watch(leadsProvider).leads.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent', style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...leads.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(e.companyName, style: const TextStyle(fontSize: 12)),
            ))
      ],
    );
  }
}
