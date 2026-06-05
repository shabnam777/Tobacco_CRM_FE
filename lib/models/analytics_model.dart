class WeeklyActivity {
  final String date;
  final int emailsSent, leadsAdded;
  WeeklyActivity({required this.date, required this.emailsSent, required this.leadsAdded});
  factory WeeklyActivity.fromJson(Map<String, dynamic> j) => WeeklyActivity(
    date: j['date'] ?? '',
    emailsSent: _i(j['emails_sent']),
    leadsAdded: _i(j['leads_added']),
  );
  static int _i(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
}

class AnalyticsModel {
  final int totalLeads, newLeads, contactedLeads, followupDue,
      repliedLeads, interestedLeads, closedDeals,
      emailsSent, emailsOpened, emailsReplied;
  final double openRate, replyRate;
  final List<WeeklyActivity> weeklyActivity;

  AnalyticsModel({
    required this.totalLeads, required this.newLeads, required this.contactedLeads,
    required this.followupDue, required this.repliedLeads, required this.interestedLeads,
    required this.closedDeals, required this.emailsSent, required this.emailsOpened,
    required this.emailsReplied, required this.openRate, required this.replyRate,
    required this.weeklyActivity,
  });

  factory AnalyticsModel.empty() => AnalyticsModel(
    totalLeads: 0, newLeads: 0, contactedLeads: 0, followupDue: 0,
    repliedLeads: 0, interestedLeads: 0, closedDeals: 0,
    emailsSent: 0, emailsOpened: 0, emailsReplied: 0,
    openRate: 0, replyRate: 0, weeklyActivity: [],
  );

  factory AnalyticsModel.fromJson(Map<String, dynamic> j) => AnalyticsModel(
    totalLeads: _i(j['total_leads']), newLeads: _i(j['new_leads']),
    contactedLeads: _i(j['contacted_leads']), followupDue: _i(j['followup_due']),
    repliedLeads: _i(j['replied_leads']), interestedLeads: _i(j['interested_leads']),
    closedDeals: _i(j['closed_deals']), emailsSent: _i(j['emails_sent']),
    emailsOpened: _i(j['emails_opened']), emailsReplied: _i(j['emails_replied']),
    openRate: _d(j['open_rate']), replyRate: _d(j['reply_rate']),
    weeklyActivity: (j['weekly_activity'] as List? ?? [])
        .map((e) => WeeklyActivity.fromJson(Map<String, dynamic>.from(e))).toList(),
  );
  static int _i(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
  static double _d(dynamic v) => v is double ? v : double.tryParse(v?.toString() ?? '') ?? 0.0;
}
