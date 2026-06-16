import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/api_service.dart';
import '../core/services/storage_service.dart';
import '../models/suggestion_model.dart';
import 'leads_provider.dart';

enum DiscoveryStatus { idle, searching, analyzing, done, error }

class SuggestionState {
  final List<SuggestionModel> suggestions;
  final List<SuggestionModel> revokedSuggestions;

  final DiscoveryStatus status;
  final String statusMessage, error, filterVerdict;
  final int foundCount, addedCount;

  const SuggestionState({
    this.suggestions = const [],
    this.revokedSuggestions = const [],
    this.status = DiscoveryStatus.idle,
    this.statusMessage = '',
    this.error = '',
    this.filterVerdict = 'All',
    this.foundCount = 0,
    this.addedCount = 0,
  });

  bool get isSearching => status == DiscoveryStatus.searching || status == DiscoveryStatus.analyzing;

  List<SuggestionModel> get filtered {
    switch (filterVerdict) {
      case 'Proceed':
        return suggestions.where((s) => s.finalVerdict == 'Proceed').toList();

      case 'Hold':
        return suggestions.where((s) => s.finalVerdict == 'Hold').toList();

      case 'Revoke':
        return revokedSuggestions;

      default:
        return suggestions;
    }
  }

  int get proceedCount => suggestions.where((s) => s.finalVerdict == 'Proceed').length;

  int get holdCount => suggestions.where((s) => s.finalVerdict == 'Hold').length;

  int get revokeCount => revokedSuggestions.length;

  SuggestionState copyWith({
    List<SuggestionModel>? suggestions,
    List<SuggestionModel>? revokedSuggestions,
    DiscoveryStatus? status,
    String? statusMessage,
    String? error,
    String? filterVerdict,
    int? foundCount,
    int? addedCount,
  }) {
    return SuggestionState(
      suggestions: suggestions ?? this.suggestions,
      revokedSuggestions: revokedSuggestions ?? this.revokedSuggestions,
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      error: error ?? this.error,
      filterVerdict: filterVerdict ?? this.filterVerdict,
      foundCount: foundCount ?? this.foundCount,
      addedCount: addedCount ?? this.addedCount,
    );
  }
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
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> discoverNewImporters() async {
    if (StorageService.isOfflineMode) {
      state = state.copyWith(error: 'Offline mode');
      return;
    }

    state = state.copyWith(
      status: DiscoveryStatus.searching,
      statusMessage: 'Searching...',
      error: '',
    );

    try {
      state = state.copyWith(
        status: DiscoveryStatus.analyzing,
        statusMessage: 'Analyzing...',
      );

      final res = await ApiService.discoverImporters();

      state = state.copyWith(
        foundCount: res['found'] ?? 0,
        addedCount: res['added'] ?? 0,
      );

      await loadSuggestions();

      state = state.copyWith(
        status: DiscoveryStatus.done,
        statusMessage: 'Completed',
      );
    } catch (e) {
      state = state.copyWith(
        status: DiscoveryStatus.error,
        error: e.toString(),
      );
    }
  }

  Future<bool> approveEntryWithRef(String id, WidgetRef ref) async {
    try {
      final res = await ApiService.approveDiscovery(id);

      SuggestionModel? item;

      final isRevoked = state.revokedSuggestions.any((e) => e.id == id);

      if (isRevoked) {
        item = state.revokedSuggestions.firstWhere((e) => e.id == id);
      } else {
        item = state.suggestions.firstWhere((e) => e.id == id);
      }

      // force update verdict
      final updatedItem = SuggestionModel(
        id: item.id,
        companyName: item.companyName,
        email: item.email,
        finalVerdict: 'Proceed',
        combinedScore: item.combinedScore,
        city: item.city,
        tradeType: item.tradeType,
        country: item.country,
      );

      state = state.copyWith(
        suggestions: [updatedItem, ...state.suggestions.where((e) => e.id != id)],
      );

      // add lead
      if (res['lead'] != null) {
        ref.read(leadsProvider.notifier).addLeadInstantly(
              Map<String, dynamic>.from(res['lead']),
            );
      }

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> revokeEntry(String id) async {
    print(id);
    try {
      await ApiService.revokeDiscovery(id);

      // remove from active
      final updatedSuggestions = state.suggestions.where((s) => s.id != id).toList();

      state = state.copyWith(
        suggestions: updatedSuggestions,
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> revalidateEntry(String id) async {
    try {
      final res = await ApiService.revalidateDiscovery(id);

      final updated = SuggestionModel.fromJson(
        Map<String, dynamic>.from(res),
      );

      final updatedList = state.suggestions.map((s) {
        if (s.id == id) {
          return updated;
        }
        return s;
      }).toList(growable: false);

      state = state.copyWith(
        suggestions: [...updatedList], // 🔥 force new reference
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void setFilter(String v) {
    state = state.copyWith(filterVerdict: v);
  }

  void clearError() {
    state = state.copyWith(error: '');
  }

  void reset() {
    state = const SuggestionState();
  }

  Future<void> deleteRevoked(String id) async {
    try {
      await ApiService.deleteRevokedById(id); // or new backend endpoint

      state = state.copyWith(
        suggestions: state.suggestions.where((e) => e.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> moveRevokeToProceed(String id) async {
    try {
      await ApiService.approveDiscovery(id);

      final updated = state.suggestions.map((s) {
        if (s.id == id) {
          return SuggestionModel(
            id: s.id,
            companyName: s.companyName,
            email: s.email,
            finalVerdict: 'Proceed',
            groqScore: s.groqScore,
            cfScore: s.cfScore,
            llamaScore: s.llamaScore,
            combinedScore: s.combinedScore,
          );
        }
        return s;
      }).toList(growable: false);

      state = state.copyWith(
        suggestions: [...updated],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> addFromRevoked(String id, WidgetRef ref) async {
    final item = state.revokedSuggestions.firstWhere((e) => e.id == id);

    await ApiService.approveDiscovery(id); // reuse existing API

    ref.read(leadsProvider.notifier).addLeadInstantly({
      "company_name": item.companyName,
      "email": item.email,
      "phone": item.phone,
    });

    state = state.copyWith(
      revokedSuggestions: state.revokedSuggestions.where((e) => e.id != id).toList(),
    );
  }

  Future<void> deleteAllRevoked() async {
    try {
      await ApiService.deleteAllRevoked();

      state = state.copyWith(
        revokedSuggestions: [],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<int> approveAllProceed(WidgetRef ref) async {
    try {
      final res = await ApiService.approveAllProceed();
      final added = res['added'] as int? ?? 0;

      // ✅ STEP 1: pick only proceed items BEFORE removing
      final proceedItems = state.suggestions.where((s) => s.finalVerdict == 'Proceed').toList();

      // ✅ STEP 2: remove proceed items from main list
      final updatedSuggestions = state.suggestions.where((s) => s.finalVerdict != 'Proceed').toList();

      // ✅ STEP 3: update state
      state = state.copyWith(
        suggestions: updatedSuggestions,
      );

      // ✅ STEP 4: push to leads instantly (IMPORTANT)
      final leadsNotifier = ref.read(leadsProvider.notifier);

      for (final item in proceedItems) {
        leadsNotifier.addLeadInstantly({
          "id": item.id,
          "company_name": item.companyName,
          "email": item.email,
          "phone": item.phone,
          "city": item.city,
          "country": item.country,
          "trade_type": item.tradeType,
          "website": item.website,
          "source": item.source,
          "status": "New",
          "created_at": DateTime.now().toIso8601String(),
        });
      }

      return added;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return 0;
    }
  }
}

final suggestionProvider = NotifierProvider<SuggestionNotifier, SuggestionState>(SuggestionNotifier.new);
