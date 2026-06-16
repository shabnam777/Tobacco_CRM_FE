import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/leads_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(analyticsProvider.notifier).loadAnalytics());
  }

  @override
  Widget build(BuildContext context) {
    final a = ref.watch(analyticsProvider);
    final l = ref.watch(leadsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        title: Text('Analytics', style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textMuted),
            onPressed: () => ref.read(analyticsProvider.notifier).loadAnalytics(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accentBlue,
        onRefresh: () => ref.read(analyticsProvider.notifier).loadAnalytics(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _statsGrid(l),
            const SizedBox(height: 16),
            _activityChart(a),
            const SizedBox(height: 16),
            _pieChart(l),
            const SizedBox(height: 16),
            _funnel(l),
            const SizedBox(height: 16),
            _insights(l),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _statsGrid(LeadsState l) {
    final items = [
      (
        'Total Leads',
        '${l.totalCount}',
        AppColors.accentBlue,
        Icons.people_rounded,
      ),
      (
        'Interested',
        '${l.interestedCount}',
        AppColors.success,
        Icons.thumb_up_rounded,
      ),
      (
        'Closed Deals',
        '${l.closedCount}',
        AppColors.accentGold,
        Icons.handshake_rounded,
      ),
      (
        'Followup Due',
        '${l.followupCount}',
        const Color.fromARGB(255, 223, 155, 79),
        Icons.schedule_rounded,
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 350, // har card max 260px lega
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) {
        final s = items[index];

        final title = s.$1;
        final value = s.$2;
        final color = s.$3;
        final icon = s.$4;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.syne(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                title,
                style: GoogleFonts.nunitoSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _activityChart(dynamic a) {
    final activity = a.weeklyActivity;

    return _card(
        'Weekly Activity',
        SizedBox(
          height: 120,
          child: activity.isEmpty
              ? Center(child: Text('No activity yet', style: GoogleFonts.nunitoSans(fontSize: 12, color: AppColors.textMuted)))
              : LineChart(LineChartData(
                  gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 1, dashArray: [4, 4])),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (v, _) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        final i = v.toInt();
                        if (i < 0 || i >= days.length) return const SizedBox();
                        return Text(days[i], style: GoogleFonts.nunitoSans(fontSize: 10, color: AppColors.textMuted));
                      },
                    )),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(touchTooltipData: LineTouchTooltipData(getTooltipColor: (_) => AppColors.bgCard)),
                  lineBarsData: [
                    _line(
                      activity
                          .asMap()
                          .entries
                          .map<FlSpot>(
                            (e) => FlSpot(
                              e.key.toDouble(),
                              e.value.emailsSent.toDouble(),
                            ),
                          )
                          .toList(),
                      AppColors.accentBlue,
                    ),
                    _line(
                      activity
                          .asMap()
                          .entries
                          .map<FlSpot>(
                            (e) => FlSpot(
                              e.key.toDouble(),
                              e.value.leadsAdded.toDouble(),
                            ),
                          )
                          .toList(),
                      AppColors.accentTeal,
                    ),
                  ],
                )),
        ));
  }

  LineChartBarData _line(List<FlSpot> spots, Color color) => LineChartBarData(
        spots: spots,
        isCurved: true,
        color: color,
        barWidth: 2.5,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
            show: true,
            gradient:
                LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withOpacity(0.15), color.withOpacity(0)])),
      );

  Widget _pieChart(LeadsState l) {
    final data = [
      (l.newCount, AppColors.statusNew, 'New'),
      (l.contactedCount, AppColors.statusContacted, 'Contacted'),
      (l.followupCount, AppColors.statusFollowup, 'Followup'),
      (l.repliedCount, AppColors.statusReplied, 'Replied'),
      (l.interestedCount, AppColors.statusInterested, 'Interested'),
      (l.closedCount, AppColors.statusClosed, 'Closed'),
    ].where((d) => d.$1 > 0).toList();

    if (data.isEmpty) return const SizedBox.shrink();

    return _card(
        'Lead Status Distribution',
        Row(children: [
          SizedBox(
              width: 130,
              height: 130,
              child: PieChart(PieChartData(
                  sections: data
                      .map((d) => PieChartSectionData(
                          value: d.$1.toDouble(), color: d.$2, radius: 48, title: '', borderSide: const BorderSide(color: Colors.white, width: 2)))
                      .toList(),
                  centerSpaceRadius: 28,
                  sectionsSpace: 2))),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: data.map((d) {
                    final pct = l.totalCount > 0 ? (d.$1 / l.totalCount * 100).toStringAsFixed(0) : '0';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: d.$2, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Expanded(child: Text(d.$3, style: GoogleFonts.nunitoSans(fontSize: 12, color: AppColors.textSecondary))),
                        Text('${d.$1} ($pct%)', style: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w700, color: d.$2)),
                      ]),
                    );
                  }).toList())),
        ]));
  }

  Widget _funnel(LeadsState l) {
    final stages = [
      (
        'Total',
        l.totalCount,
        AppColors.accentBlue,
        Icons.dataset_rounded,
      ),
      (
        'Contacted',
        l.contactedCount + l.followupCount + l.repliedCount + l.interestedCount + l.closedCount,
        AppColors.accentPurple,
        Icons.call_rounded,
      ),
      (
        'Engaged',
        l.repliedCount + l.interestedCount + l.closedCount,
        AppColors.accentBlueLt,
        Icons.forum_rounded,
      ),
      (
        'Interested',
        l.interestedCount + l.closedCount,
        AppColors.verdictProceed,
        Icons.favorite_rounded,
      ),
      (
        'Closed',
        l.closedCount,
        AppColors.accentGold,
        Icons.verified_rounded,
      ),
    ];
    final max = l.totalCount > 0 ? l.totalCount : 1;
    return _card(
        'Sales Funnel',
        Column(
            children: stages.map((s) {
          final stages = [
            (
              'Total',
              l.totalCount,
              AppColors.accentBlue,
              Icons.dataset_rounded,
            ),
            (
              'Contacted',
              l.contactedCount + l.followupCount + l.repliedCount + l.interestedCount + l.closedCount,
              AppColors.accentPurple,
              Icons.call_rounded,
            ),
            (
              'Engaged',
              l.repliedCount + l.interestedCount + l.closedCount,
              AppColors.accentTeal,
              Icons.forum_rounded,
            ),
            (
              'Interested',
              l.interestedCount + l.closedCount,
              AppColors.success,
              Icons.favorite_rounded,
            ),
            (
              'Closed',
              l.closedCount,
              AppColors.accentGold,
              Icons.verified_rounded,
            ),
          ];
          final title = s.$1;
          final value = s.$2;
          final color = s.$3;
          final icon = s.$4;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Icon(icon, size: 16, color: color),
                Text(title, style: GoogleFonts.nunitoSans(fontSize: 12, color: AppColors.textSecondary)),
                Text('$value', style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child:
                      LinearProgressIndicator(value: (value / max).clamp(0.0, 1.0), backgroundColor: AppColors.bgInput, color: color, minHeight: 8)),
            ]),
          );
        }).toList()));
  }

  Widget _insights(LeadsState l) => _card(
      '💡 Insights',
      Column(children: [
        _insight('${l.interestedCount} importers are actively interested', 'Follow up within 48 hours', AppColors.success),
        if (l.followupCount > 0) _insight('${l.followupCount} followups overdue', 'Take action today', AppColors.warning),
        _insight('Monday campaigns show highest open rates', 'Schedule sends for Monday 9–11 AM', AppColors.accentBlue),
        _insight('UAE mainland leads convert faster', 'Prioritize Dubai & Sharjah contacts', AppColors.accentGold),
      ]));

  Widget _insight(String title, String sub, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 5), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.nunitoSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text(sub, style: GoogleFonts.nunitoSans(fontSize: 11, color: AppColors.textSecondary)),
          ])),
        ]),
      );

  Widget _card(String title, Widget child) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.cardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 3, height: 16, decoration: BoxDecoration(color: AppColors.accentBlue, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text(title, style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 14),
          child,
        ]),
      );
}
