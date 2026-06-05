class NoteEntry {
  final String note;
  final DateTime timestamp;
  NoteEntry({required this.note, required this.timestamp});
  factory NoteEntry.fromJson(Map<String, dynamic> j) => NoteEntry(
    note: j['note'] ?? '', timestamp: DateTime.tryParse(j['timestamp'] ?? '') ?? DateTime.now());
  Map<String, dynamic> toJson() => {'note': note, 'timestamp': timestamp.toIso8601String()};
}

class LeadModel {
  final String id, companyName, email, status, country;
  final String? contactPerson, phone, whatsapp, city, address,
      website, tradeType, annualTurnover, employeeCount, licenseNo, notes;
  final List<String> tags, products;
  final List<NoteEntry> noteHistory;
  final int followupCount;
  final DateTime? lastContacted, nextFollowup;
  final DateTime createdAt;
  final String source;

  LeadModel({
    required this.id, required this.companyName, required this.email,
    required this.status, required this.country,
    this.contactPerson, this.phone, this.whatsapp, this.city, this.address,
    this.website, this.tradeType, this.annualTurnover, this.employeeCount,
    this.licenseNo, this.notes,
    this.tags = const [], this.products = const [],
    this.noteHistory = const [],
    this.followupCount = 0, this.lastContacted, this.nextFollowup,
    DateTime? createdAt, this.source = 'manual',
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isFollowupDue => nextFollowup != null && nextFollowup!.isBefore(DateTime.now()) && status == 'Contacted';

  String get initials {
    final parts = companyName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return companyName.length >= 2 ? companyName.substring(0, 2).toUpperCase() : companyName.toUpperCase();
  }

  factory LeadModel.fromJson(Map<String, dynamic> j) => LeadModel(
    id: j['id']?.toString() ?? '',
    companyName: j['company_name'] ?? j['companyName'] ?? '',
    contactPerson: j['contact_person'] ?? j['contactPerson'],
    email: j['email'] ?? '',
    phone: j['phone'], whatsapp: j['whatsapp'],
    country: j['country'] ?? 'UAE', city: j['city'], address: j['address'],
    website: j['website'],
    tradeType: j['trade_type'] ?? j['tradeType'],
    annualTurnover: j['annual_turnover'] ?? j['annualTurnover'],
    employeeCount: j['employee_count'] ?? j['employeeCount'],
    licenseNo: j['license_no'] ?? j['licenseNo'],
    tags: List<String>.from(j['tags'] ?? []),
    products: List<String>.from(j['products'] ?? []),
    notes: j['notes'], status: j['status'] ?? 'New',
    noteHistory: (j['note_history'] ?? j['noteHistory'] ?? [])
        .map<NoteEntry>((e) => NoteEntry.fromJson(Map<String, dynamic>.from(e))).toList(),
    followupCount: (j['followup_count'] ?? j['followupCount'] ?? 0) as int,
    lastContacted: j['last_contacted'] != null ? DateTime.tryParse(j['last_contacted'].toString()) : null,
    nextFollowup: j['next_followup'] != null ? DateTime.tryParse(j['next_followup'].toString()) : null,
    createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at'].toString()) : null,
    source: j['source'] ?? 'manual',
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'company_name': companyName, 'contact_person': contactPerson,
    'email': email, 'phone': phone, 'whatsapp': whatsapp, 'country': country,
    'city': city, 'address': address, 'website': website, 'trade_type': tradeType,
    'annual_turnover': annualTurnover, 'employee_count': employeeCount,
    'license_no': licenseNo, 'tags': tags, 'products': products, 'notes': notes,
    'status': status, 'followup_count': followupCount,
    'last_contacted': lastContacted?.toIso8601String(),
    'next_followup': nextFollowup?.toIso8601String(),
    'created_at': createdAt.toIso8601String(), 'source': source,
    'note_history': noteHistory.map((n) => n.toJson()).toList(),
  };

  LeadModel copyWith({String? status, List<NoteEntry>? noteHistory}) => LeadModel(
    id: id, companyName: companyName, email: email,
    status: status ?? this.status, country: country,
    contactPerson: contactPerson, phone: phone, whatsapp: whatsapp,
    city: city, address: address, website: website, tradeType: tradeType,
    annualTurnover: annualTurnover, employeeCount: employeeCount,
    licenseNo: licenseNo, notes: notes, tags: tags, products: products,
    noteHistory: noteHistory ?? this.noteHistory,
    followupCount: followupCount, lastContacted: lastContacted,
    nextFollowup: nextFollowup, createdAt: createdAt, source: source,
  );
}
