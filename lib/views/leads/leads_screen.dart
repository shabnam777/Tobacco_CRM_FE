import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/leads_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/lead_tile.dart';
import '../../widgets/primary_button.dart';
import 'lead_detail_screen.dart';
import 'add_edit_lead_screen.dart';

class LeadsScreen extends ConsumerStatefulWidget {
  const LeadsScreen({super.key});
  @override
  ConsumerState<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends ConsumerState<LeadsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _search = TextEditingController();
  static const _tabDefs = [
    ('All','All'),('New','New'),('Contacted','Contacted'),
    ('Followup','Followup Due'),('Replied','Replied'),
    ('Interested','Interested'),('Closed','Closed'),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _tabDefs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(leadsProvider.notifier).loadLeads());
  }

  @override
  void dispose() { _tabs.dispose(); _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        title: Text('Leads', style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted),
              onPressed: () => ref.read(leadsProvider.notifier).loadLeads()),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: TextField(
                controller: _search,
                style: GoogleFonts.nunitoSans(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search company, email, city...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                  suffixIcon: _search.text.isNotEmpty
                      ? GestureDetector(onTap: () { _search.clear(); ref.read(leadsProvider.notifier).setSearch(''); },
                          child: const Icon(Icons.close, color: AppColors.textMuted, size: 18))
                      : null,
                  filled: true, fillColor: AppColors.bgInput,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accentBlue, width: 2))),
                onChanged: (v) => ref.read(leadsProvider.notifier).setSearch(v))),
            Consumer(builder: (_, ref, __) {
              final s = ref.watch(leadsProvider);
              return TabBar(
                controller: _tabs, isScrollable: true, tabAlignment: TabAlignment.start,
                indicatorColor: AppColors.accentBlue, labelColor: AppColors.accentBlue,
                unselectedLabelColor: AppColors.textMuted, dividerColor: AppColors.border,
                labelStyle: GoogleFonts.nunitoSans(fontSize: 12, fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.nunitoSans(fontSize: 12),
                tabs: _tabDefs.map((t) {
                  final count = t.$2 == 'All' ? s.totalCount : s.byStatus(t.$2).length;
                  return Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(t.$1),
                    if (count > 0) ...[
                      const SizedBox(width: 5),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: AppColors.accentBlue.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                        child: Text('$count', style: GoogleFonts.nunitoSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.accentBlue))),
                    ],
                  ]));
                }).toList());
            }),
          ])),
      ),
      body: TabBarView(
        controller: _tabs,
        children: _tabDefs.map((t) => _LeadList(status: t.$2)).toList()),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditLeadScreen())),
        backgroundColor: AppColors.accentBlue, foregroundColor: Colors.white,
        child: const Icon(Icons.add)),
    );
  }
}

class _LeadList extends ConsumerWidget {
  final String status;
  const _LeadList({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(leadsProvider);
    final leads = state.byStatus(status);

    if (state.isLoading && leads.isEmpty) {
      return ListView.builder(padding: const EdgeInsets.all(14), itemCount: 5,
        itemBuilder: (_, __) => Container(height: 84, margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border))));
    }

    if (leads.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.people_outline, size: 48, color: AppColors.textDisabled), const SizedBox(height: 12),
        Text('No $status Leads', style: GoogleFonts.syne(fontSize: 15, color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(status == 'All' ? 'Add your first lead or discover via AI' : 'Leads with "$status" status appear here',
            style: GoogleFonts.nunitoSans(fontSize: 13, color: AppColors.textMuted)),
        if (status == 'All') ...[
          const SizedBox(height: 20),
          PrimaryButton(label: 'Add Lead', icon: Icons.add, width: 160,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditLeadScreen()))),
        ],
      ]));
    }

    return RefreshIndicator(
      color: AppColors.accentBlue,
      onRefresh: () => ref.read(leadsProvider.notifier).loadLeads(),
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: leads.length,
        itemBuilder: (_, i) => LeadTile(
          lead: leads[i],
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LeadDetailScreen(leadId: leads[i].id))),
          onEmail: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LeadDetailScreen(leadId: leads[i].id, openEmail: true))),
          onDelete: () => _confirmDelete(context, ref, leads[i].id, leads[i].companyName),
          onStatusChanged: (s) => ref.read(leadsProvider.notifier).updateStatus(leads[i].id, s),
        )));
  }

  void _confirmDelete(BuildContext ctx, WidgetRef ref, String id, String name) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: Text('Delete Lead', style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      content: Text('Remove "$name"? This cannot be undone.', style: GoogleFonts.nunitoSans(fontSize: 14, color: AppColors.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.nunitoSans(color: AppColors.textMuted))),
        TextButton(onPressed: () { ref.read(leadsProvider.notifier).deleteLead(id); Navigator.pop(ctx); },
            child: Text('Delete', style: GoogleFonts.nunitoSans(color: AppColors.error, fontWeight: FontWeight.w700))),
      ]));
  }
}
