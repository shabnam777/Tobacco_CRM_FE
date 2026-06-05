class EmailLogModel {
  final String id, toEmail, subject, body, templateType, status;
  final String? leadId, campaignId, errorMessage;
  final DateTime sentAt;

  EmailLogModel({
    required this.id, this.leadId, this.campaignId,
    required this.toEmail, required this.subject, required this.body,
    required this.templateType, required this.status, this.errorMessage,
    required this.sentAt,
  });

  bool get isSuccessful => status == 'sent' || status == 'delivered' || status == 'opened' || status == 'replied';
  String get statusIcon => isSuccessful ? '✅' : '❌';

  factory EmailLogModel.fromJson(Map<String, dynamic> j) => EmailLogModel(
    id: j['id']?.toString() ?? '', leadId: j['lead_id']?.toString(),
    campaignId: j['campaign_id']?.toString(), toEmail: j['to_email'] ?? '',
    subject: j['subject'] ?? '', body: j['body'] ?? '',
    templateType: j['template_type'] ?? 'Cold Outreach',
    status: j['status'] ?? 'sent', errorMessage: j['error_message'],
    sentAt: DateTime.tryParse(j['sent_at']?.toString() ?? '') ?? DateTime.now(),
  );
}
