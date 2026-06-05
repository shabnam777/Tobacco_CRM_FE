import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/lead_model.dart';
import '../core/services/api_service.dart';
import '../core/services/storage_service.dart';

class LeadsState {
  final List<LeadModel> leads;
  final bool isLoading;
  final String error, search, filterStatus;

  const LeadsState({this.leads = const [], this.isLoading = false,
      this.error = '', this.search = '', this.filterStatus = 'All'});

  List<LeadModel> get filtered {
    var r = List<LeadModel>.from(leads);
    if (filterStatus != 'All') r = r.where((l) => l.status == filterStatus).toList();
    if (search.isNotEmpty) {
      final q = search.toLowerCase();
      r = r.where((l) => l.companyName.toLowerCase().contains(q) ||
          l.email.toLowerCase().contains(q) ||
          (l.contactPerson?.toLowerCase().contains(q) ?? false) ||
          (l.city?.toLowerCase().contains(q) ?? false)).toList();
    }
    return r;
  }

  List<LeadModel> byStatus(String s) => s == 'All' ? filtered : filtered.where((l) => l.status == s).toList();

  int get totalCount      => leads.length;
  int get newCount        => leads.where((l) => l.status == 'New').length;
  int get contactedCount  => leads.where((l) => l.status == 'Contacted').length;
  int get followupCount   => leads.where((l) => l.status == 'Followup Due').length;
  int get repliedCount    => leads.where((l) => l.status == 'Replied').length;
  int get interestedCount => leads.where((l) => l.status == 'Interested').length;
  int get closedCount     => leads.where((l) => l.status == 'Closed').length;
  List<LeadModel> get hotLeads     => leads.where((l) => l.status == 'Interested').take(5).toList();
  List<LeadModel> get followupsDue => leads.where((l) => l.status == 'Followup Due' || l.isFollowupDue).toList();

  LeadsState copyWith({List<LeadModel>? leads, bool? isLoading, String? error, String? search, String? filterStatus}) =>
      LeadsState(leads: leads ?? this.leads, isLoading: isLoading ?? this.isLoading,
          error: error ?? this.error, search: search ?? this.search, filterStatus: filterStatus ?? this.filterStatus);
}

class LeadsNotifier extends Notifier<LeadsState> {
  @override
  LeadsState build() => const LeadsState();

  Future<void> loadLeads() async {
    state = state.copyWith(isLoading: true, error: '');
    if (StorageService.isOfflineMode) {
      final cached = StorageService.getCachedLeads();
      state = state.copyWith(
        leads: cached?.map((e) => LeadModel.fromJson(Map<String, dynamic>.from(e))).toList() ?? [],
        isLoading: false);
      return;
    }
    try {
      final data = await ApiService.getLeads();
      final leads = data.map((e) => LeadModel.fromJson(Map<String, dynamic>.from(e))).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      StorageService.cacheLeads(data);
      state = state.copyWith(leads: leads, isLoading: false, error: '');
    } catch (e) {
      final cached = StorageService.getCachedLeads();
      state = state.copyWith(
        leads: cached?.map((e) => LeadModel.fromJson(Map<String, dynamic>.from(e))).toList() ?? state.leads,
        isLoading: false, error: e.toString());
    }
  }

  // KEY FIX: Discovery approve → instant add without refresh
  void addLeadInstantly(Map<String, dynamic> leadJson) {
    final newLead = LeadModel.fromJson(leadJson);
    if (state.leads.any((l) => l.id == newLead.id || l.email == newLead.email)) return;
    final updated = [newLead, ...state.leads];
    state = state.copyWith(leads: updated);
    StorageService.cacheLeads(updated.map((l) => l.toJson()).toList());
  }

  void loadFromPreloaded(List<dynamic> data) {
    state = state.copyWith(
      leads: data.map((e) => LeadModel.fromJson(Map<String, dynamic>.from(e))).toList(),
      isLoading: false);
  }

  Future<bool> addLead(Map<String, dynamic> data) async {
    final tempId = const Uuid().v4();
    final temp = LeadModel.fromJson({...data, 'id': tempId, 'created_at': DateTime.now().toIso8601String()});
    state = state.copyWith(leads: [temp, ...state.leads]);
    if (StorageService.isOfflineMode) return true;
    try {
      final res = await ApiService.createLead(data);
      final server = LeadModel.fromJson(Map<String, dynamic>.from(res));
      state = state.copyWith(leads: state.leads.map((l) => l.id == tempId ? server : l).toList());
      return true;
    } catch (e) { state = state.copyWith(error: e.toString()); return false; }
  }

  Future<bool> updateLead(String id, Map<String, dynamic> data) async {
    final idx = state.leads.indexWhere((l) => l.id == id);
    if (idx < 0) return false;
    final old = state.leads[idx];
    final updated = List<LeadModel>.from(state.leads);
    updated[idx] = LeadModel.fromJson({...old.toJson(), ...data});
    state = state.copyWith(leads: updated);
    if (StorageService.isOfflineMode) return true;
    try { await ApiService.updateLead(id, data); return true; }
    catch (e) {
      final rev = List<LeadModel>.from(state.leads); rev[idx] = old;
      state = state.copyWith(leads: rev, error: e.toString()); return false;
    }
  }

  Future<bool> updateStatus(String id, String status) async {
    final idx = state.leads.indexWhere((l) => l.id == id);
    if (idx < 0) return false;
    final old = state.leads[idx];
    final updated = List<LeadModel>.from(state.leads);
    updated[idx] = old.copyWith(status: status);
    state = state.copyWith(leads: updated);
    if (StorageService.isOfflineMode) return true;
    try { await ApiService.updateLeadStatus(id, status); return true; }
    catch (e) {
      final rev = List<LeadModel>.from(state.leads); rev[idx] = old;
      state = state.copyWith(leads: rev); return false;
    }
  }

  Future<bool> deleteLead(String id) async {
    final idx = state.leads.indexWhere((l) => l.id == id);
    if (idx < 0) return false;
    final backup = state.leads[idx];
    state = state.copyWith(leads: List<LeadModel>.from(state.leads)..removeAt(idx));
    if (StorageService.isOfflineMode) return true;
    try { await ApiService.deleteLead(id); return true; }
    catch (e) {
      state = state.copyWith(leads: List<LeadModel>.from(state.leads)..insert(idx, backup)); return false;
    }
  }

  Future<bool> addNote(String leadId, String note) async {
    final idx = state.leads.indexWhere((l) => l.id == leadId);
    if (idx < 0) return false;
    final entry = NoteEntry(note: note, timestamp: DateTime.now());
    final history = [entry, ...state.leads[idx].noteHistory];
    final updated = List<LeadModel>.from(state.leads);
    updated[idx] = state.leads[idx].copyWith(noteHistory: history);
    state = state.copyWith(leads: updated);
    if (StorageService.isOfflineMode) return true;
    try { await ApiService.addNote(leadId, note); } catch (_) {}
    return true;
  }

  void setSearch(String q) => state = state.copyWith(search: q);
  void setFilter(String s) => state = state.copyWith(filterStatus: s);
  void clearError()        => state = state.copyWith(error: '');
}

final leadsProvider = NotifierProvider<LeadsNotifier, LeadsState>(LeadsNotifier.new);
final leadCountProvider    = Provider((ref) => ref.watch(leadsProvider).totalCount);
final followupsDueProvider = Provider((ref) => ref.watch(leadsProvider).followupsDue);
final hotLeadsProvider     = Provider((ref) => ref.watch(leadsProvider).hotLeads);
