import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analytics_model.dart';
import '../core/services/api_service.dart';

class AnalyticsNotifier extends Notifier<AnalyticsModel> {
  @override
  AnalyticsModel build() => AnalyticsModel.empty();

  Future<void> loadAnalytics() async {
    try {
      final data = await ApiService.getAnalytics();
      state = AnalyticsModel.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {}
  }
}

final analyticsProvider = NotifierProvider<AnalyticsNotifier, AnalyticsModel>(AnalyticsNotifier.new);
