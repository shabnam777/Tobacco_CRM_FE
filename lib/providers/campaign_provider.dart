import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/campaign_model.dart';
import '../models/email_log_model.dart';
import '../core/services/api_service.dart';
import '../core/services/storage_service.dart';

enum CampaignStatus { idle, loading, sending, success, error }

class CampaignState {
  final List<CampaignModel> campaigns;
  final List<EmailLogModel> emailLogs;
  final CampaignStatus status;
  final String error;
  final String? generatedSubject, generatedBody;
  final bool isGenerating;

  const CampaignState({this.campaigns = const [], this.emailLogs = const [],
      this.status = CampaignStatus.idle, this.error = '',
      this.generatedSubject, this.generatedBody, this.isGenerating = false});

  int get totalSent => campaigns.fold(0, (s, c) => s + c.sentEmails);
  bool get isSending => status == CampaignStatus.sending;

  CampaignState copyWith({List<CampaignModel>? campaigns, List<EmailLogModel>? emailLogs,
      CampaignStatus? status, String? error, String? generatedSubject, String? generatedBody,
      bool? isGenerating, bool clearGenerated = false}) =>
      CampaignState(
        campaigns: campaigns ?? this.campaigns, emailLogs: emailLogs ?? this.emailLogs,
        status: status ?? this.status, error: error ?? this.error,
        generatedSubject: clearGenerated ? null : (generatedSubject ?? this.generatedSubject),
        generatedBody: clearGenerated ? null : (generatedBody ?? this.generatedBody),
        isGenerating: isGenerating ?? this.isGenerating);
}

class CampaignNotifier extends Notifier<CampaignState> {
  @override
  CampaignState build() => const CampaignState();

  Future<void> loadCampaigns() async {
    state = state.copyWith(status: CampaignStatus.loading);
    try {
      final data = await ApiService.getCampaigns();
      state = state.copyWith(
        campaigns: data.map((e) => CampaignModel.fromJson(Map<String, dynamic>.from(e))).toList(),
        status: CampaignStatus.idle);
    } catch (e) { state = state.copyWith(status: CampaignStatus.error, error: e.toString()); }
  }

  Future<void> loadEmailLogs(String leadId) async {
    try {
      final data = await ApiService.getEmailHistory(leadId);
      state = state.copyWith(emailLogs: data.map((e) => EmailLogModel.fromJson(Map<String, dynamic>.from(e))).toList());
    } catch (_) {}
  }

  Future<bool> sendEmail({required String leadId, required String toEmail,
      required String subject, required String body, String templateType = 'Cold Outreach', String? campaignId}) async {
    state = state.copyWith(status: CampaignStatus.sending, error: '');
    try {
      await ApiService.sendEmail({'lead_id': leadId, 'to_email': toEmail, 'subject': subject,
          'body': body, 'template_type': templateType, if (campaignId != null) 'campaign_id': campaignId});
      final log = EmailLogModel(id: DateTime.now().millisecondsSinceEpoch.toString(),
          leadId: leadId, toEmail: toEmail, subject: subject, body: body,
          templateType: templateType, status: 'sent', sentAt: DateTime.now());
      state = state.copyWith(status: CampaignStatus.success, emailLogs: [log, ...state.emailLogs]);
      return true;
    } catch (e) { state = state.copyWith(status: CampaignStatus.error, error: e.toString()); return false; }
  }

  Future<void> generateEmail({required String companyName, required String contactPerson,
      required String templateType, String? previousContext}) async {
    state = state.copyWith(isGenerating: true, clearGenerated: true);
    try {
      final res = await ApiService.generateEmail({'company_name': companyName,
          'contact_person': contactPerson, 'template_type': templateType,
          if (previousContext != null) 'previous_context': previousContext});
      state = state.copyWith(generatedSubject: res['subject']?.toString() ?? '',
          generatedBody: res['body']?.toString() ?? '', isGenerating: false);
    } catch (e) {
      final s = StorageService.getSenderName().isNotEmpty ? StorageService.getSenderName() : 'Export Manager';
      final co = StorageService.getCompanyName().isNotEmpty ? StorageService.getCompanyName() : 'Premium Tobacco Exports India';
      state = state.copyWith(isGenerating: false, error: e.toString(),
          generatedSubject: 'Partnership Opportunity: Premium Indian Tobacco for $companyName',
          generatedBody: 'Dear Sir/Madam,\n\nI am writing from $co regarding a potential business opportunity for $companyName.\n\nWe export premium Indian Beedi, Natural Leaf Tobacco, and Hookah Tobacco to the UAE market.\n\nMay I send you our catalogue?\n\nBest regards,\n$s\n$co\nIndia');
    }
  }

  Future<bool> createCampaign(Map<String, dynamic> data) async {
    try {
      final res = await ApiService.createCampaign(data);
      state = state.copyWith(campaigns: [CampaignModel.fromJson(Map<String, dynamic>.from(res)), ...state.campaigns]);
      return true;
    } catch (e) { state = state.copyWith(error: e.toString()); return false; }
  }

  void clearGenerated() => state = state.copyWith(clearGenerated: true);
  void resetStatus()    => state = state.copyWith(status: CampaignStatus.idle, error: '');
}

final campaignProvider = NotifierProvider<CampaignNotifier, CampaignState>(CampaignNotifier.new);
