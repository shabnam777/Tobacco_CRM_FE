class CampaignModel {
  final String id, name, type, status;
  final int totalEmails, sentEmails, failedEmails, openedEmails, repliedEmails;
  final String? subject, templateType;
  final List<String> leadIds;
  final DateTime createdAt;
  final DateTime? scheduledAt, completedAt;

  CampaignModel({
    required this.id, required this.name, required this.type, required this.status,
    this.totalEmails = 0, this.sentEmails = 0, this.failedEmails = 0,
    this.openedEmails = 0, this.repliedEmails = 0,
    this.subject, this.templateType, this.leadIds = const [],
    required this.createdAt, this.scheduledAt, this.completedAt,
  });

  double get openRate => sentEmails > 0 ? openedEmails / sentEmails * 100 : 0;
  double get replyRate => sentEmails > 0 ? repliedEmails / sentEmails * 100 : 0;

  factory CampaignModel.fromJson(Map<String, dynamic> j) => CampaignModel(
    id: j['id']?.toString() ?? '', name: j['name'] ?? '',
    type: j['type'] ?? 'Bulk Outreach', status: j['status'] ?? 'Draft',
    totalEmails: _i(j['total_emails']), sentEmails: _i(j['sent_emails']),
    failedEmails: _i(j['failed_emails']), openedEmails: _i(j['opened_emails']),
    repliedEmails: _i(j['replied_emails']),
    subject: j['subject'], templateType: j['template_type'],
    leadIds: List<String>.from(j['lead_ids'] ?? []),
    createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
    scheduledAt: j['scheduled_at'] != null ? DateTime.tryParse(j['scheduled_at'].toString()) : null,
    completedAt: j['completed_at'] != null ? DateTime.tryParse(j['completed_at'].toString()) : null,
  );
  static int _i(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
}
