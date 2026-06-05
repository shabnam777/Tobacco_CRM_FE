import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/suggestion_model.dart';
import '../core/services/api_service.dart';
import '../core/services/storage_service.dart';
import 'leads_provider.dart';

enum DiscoveryStatus { idle, searching, analyzing, done, error }

class SuggestionState {
  final List<SuggestionModel> suggestions;
  final DiscoveryStatus status;
  final String statusMessage, error, filterVerdict;
  final int foundCount, addedCount;

  const SuggestionState({this.suggestions = const [], this.status = DiscoveryStatus.idle,
      this.statusMessage = '', this.error = '', this.filterVerdict = 'All',
      this.foundCount = 0, this.addedCount = 0});

  bool get isSearching => status == DiscoveryStatus.searching || status == DiscoveryStatus.analyzing;
  List<SuggestionModel> get filtered => filterVerdict == 'All'
      ? suggestions : suggestions.where((s) => s.finalVerdict == filterVerdict).toList();
  int get proceedCount => suggestions.where((s) => s.finalVerdict == 'Proceed').length;
  int get holdCount    => suggestions.where((s) => s.finalVerdict == 'Hold').length;
  int get revokeCount  => suggestions.where((s) => s.finalVerdict == 'Revoke').length;

  SuggestionState copyWith({List<SuggestionModel>? suggestions, DiscoveryStatus? status,
      String? statusMessage, String? error, String? filterVerdict, int? foundCount, int? addedCount}) =>
      SuggestionState(suggestions: suggestions ?? this.suggestions, status: status ?? this.status,
          statusMessage: statusMessage ?? this.statusMessage, error: error ?? this.error,
          filterVerdict: filterVerdict ?? this.filterVerdict,
          foundCount: foundCount ?? this.foundCount, addedCount: addedCount ?? this.addedCount);
}

class SuggestionNotifier extends Notifier<SuggestionState> {
  @override
  SuggestionState build() => const SuggestionState();

  Future<void> loadSuggestions() async {
    if (StorageService.isOfflineMode) return;
    try {
      final data = await ApiService.getDiscoverySuggestions();
      final list = data.map((e) => SuggestionModel.fromJson(Map<String, dynamic>.from(e))).toList()
        ..sort((a, b) => b.combinedScore.compareTo(a.combinedScore));
      state = state.copyWith(suggestions: list, error: '');
    } catch (e) { state = state.copyWith(error: e.toString()); }
  }

  Future<void> discoverNewImporters() async {
    if (StorageService.isOfflineMode) {
      state = state.copyWith(error: 'Cannot discover in offline mode');
      return;
    }
    state = state.copyWith(status: DiscoveryStatus.searching,
        statusMessage: 'Calling Groq + Cloudflare + Llama...', error: '');
    try {
      state = state.copyWith(status: DiscoveryStatus.analyzing,
          statusMessage: 'Analyzing UAE importers (~30 sec)...');
      final res = await ApiService.discoverImporters();
      state = state.copyWith(statusMessage: 'Loading results...',
          foundCount: res['found'] ?? 0, addedCount: res['added'] ?? 0);
      await loadSuggestions();
      state = state.copyWith(status: DiscoveryStatus.done,
          statusMessage: '${state.addedCount} new importers added & analyzed');
    } catch (e) {
      state = state.copyWith(status: DiscoveryStatus.error,
          error: e.toString().replaceAll('ApiException: ', ''),
          statusMessage: 'Discovery failed');
    }
  }

  // KEY: Approve → instantly adds to leads list via leadsProvider
  Future<bool> approveEntryWithRef(String id, WidgetRef ref) async {
    try {
      final res = await ApiService.approveDiscovery(id);
      state = state.copyWith(suggestions: state.suggestions.where((s) => s.id != id).toList());
      if (res['lead'] != null) {
        ref.read(leadsProvider.notifier).addLeadInstantly(Map<String, dynamic>.from(res['lead']));
      } else {
        await ref.read(leadsProvider.notifier).loadLeads();
      }
      return true;
    } catch (e) { state = state.copyWith(error: e.toString()); return false; }
  }

  Future<bool> revokeEntry(String id) async {
    try {
      await ApiService.revokeDiscovery(id);
      state = state.copyWith(suggestions: state.suggestions.where((s) => s.id != id).toList());
      return true;
    } catch (e) { state = state.copyWith(error: e.toString()); return false; }
  }

  Future<int> approveAllProceed(WidgetRef ref) async {
    try {
      final res = await ApiService.approveAllProceed();
      final added = res['added'] as int? ?? 0;
      state = state.copyWith(suggestions: state.suggestions.where((s) => s.finalVerdict != 'Proceed').toList());
      await ref.read(leadsProvider.notifier).loadLeads();
      return added;
    } catch (_) { return 0; }
  }

  Future<void> revalidateEntry(String id) async {
    try {
      final res = await ApiService.revalidateDiscovery(id);
      final updated = SuggestionModel.fromJson(Map<String, dynamic>.from(res));
      state = state.copyWith(suggestions: state.suggestions.map((s) => s.id == id ? updated : s).toList());
    } catch (e) { state = state.copyWith(error: e.toString()); }
  }

  void setFilter(String v) => state = state.copyWith(filterVerdict: v);
  void clearError()        => state = state.copyWith(error: '');
  void reset()             => state = const SuggestionState();
}

final suggestionProvider = NotifierProvider<SuggestionNotifier, SuggestionState>(SuggestionNotifier.new);
