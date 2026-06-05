class SuggestionModel {
  final String id, companyName, email, source, status, finalVerdict;
  final String? contactPerson, phone, whatsapp, city, website, tradeType,
      annualTurnover, notes;
  final String country;
  final List<String> tags, products, riskFlags;
  final int groqScore, cfScore, llamaScore, combinedScore;
  final String groqAnalysis, groqRecommendation;
  final String cfAnalysis, cfRecommendation, cfLegitimacy, cfOutreachPotential;
  final String llamaAnalysis, llamaRecommendation;
  final String verdictConfidence, combinedInsight, suggestedAction, riskLevel;
  final bool analysisDone;
  final DateTime? createdAt;

  SuggestionModel({
    required this.id, required this.companyName, required this.email,
    this.contactPerson, this.phone, this.whatsapp,
    this.country = 'UAE', this.city, this.website, this.tradeType,
    this.annualTurnover, this.notes,
    this.tags = const [], this.products = const [], this.riskFlags = const [],
    this.source = 'discovery', this.status = 'pending',
    this.groqScore = 0, this.groqAnalysis = '', this.groqRecommendation = 'Hold',
    this.cfScore = 0, this.cfAnalysis = '', this.cfRecommendation = 'Hold',
    this.cfLegitimacy = 'Medium', this.cfOutreachPotential = 'Medium',
    this.llamaScore = 0, this.llamaAnalysis = '', this.llamaRecommendation = 'Hold',
    this.combinedScore = 0, this.finalVerdict = 'Hold',
    this.verdictConfidence = 'Low', this.combinedInsight = '',
    this.suggestedAction = '', this.riskLevel = 'Medium',
    this.analysisDone = false, this.createdAt,
  });

  String get initials {
    final p = companyName.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return companyName.length >= 2 ? companyName.substring(0, 2).toUpperCase() : companyName.toUpperCase();
  }
  bool get isProceed => finalVerdict == 'Proceed';
  bool get isRevoke  => finalVerdict == 'Revoke';

  factory SuggestionModel.fromJson(Map<String, dynamic> j) => SuggestionModel(
    id: j['id']?.toString() ?? '',
    companyName: j['company_name'] ?? j['companyName'] ?? '',
    contactPerson: j['contact_person'] ?? j['contactPerson'],
    email: j['email'] ?? '', phone: j['phone'], whatsapp: j['whatsapp'],
    country: j['country'] ?? 'UAE', city: j['city'], website: j['website'],
    tradeType: j['trade_type'] ?? j['tradeType'],
    annualTurnover: j['annual_turnover'] ?? j['annualTurnover'], notes: j['notes'],
    tags: List<String>.from(j['tags'] ?? []),
    products: List<String>.from(j['products'] ?? []),
    riskFlags: List<String>.from(j['risk_flags'] ?? j['riskFlags'] ?? []),
    source: j['source'] ?? 'discovery', status: j['status'] ?? 'pending',
    groqScore: _i(j['groq_score'] ?? j['groqScore']),
    groqAnalysis: j['groq_analysis'] ?? j['groqAnalysis'] ?? '',
    groqRecommendation: j['groq_recommendation'] ?? j['groqRecommendation'] ?? 'Hold',
    cfScore: _i(j['cf_score'] ?? j['cfScore']),
    cfAnalysis: j['cf_analysis'] ?? j['cfAnalysis'] ?? '',
    cfRecommendation: j['cf_recommendation'] ?? j['cfRecommendation'] ?? 'Hold',
    cfLegitimacy: j['cf_legitimacy'] ?? j['cfLegitimacy'] ?? 'Medium',
    cfOutreachPotential: j['cf_outreach_potential'] ?? j['cfOutreachPotential'] ?? 'Medium',
    llamaScore: _i(j['llama_score'] ?? j['llamaScore']),
    llamaAnalysis: j['llama_analysis'] ?? j['llamaAnalysis'] ?? '',
    llamaRecommendation: j['llama_recommendation'] ?? j['llamaRecommendation'] ?? 'Hold',
    combinedScore: _i(j['combined_score'] ?? j['combinedScore']),
    finalVerdict: j['final_verdict'] ?? j['finalVerdict'] ?? 'Hold',
    verdictConfidence: j['verdict_confidence'] ?? j['verdictConfidence'] ?? 'Low',
    combinedInsight: j['combined_insight'] ?? j['combinedInsight'] ?? '',
    suggestedAction: j['suggested_action'] ?? j['suggestedAction'] ?? '',
    riskLevel: j['risk_level'] ?? j['riskLevel'] ?? 'Medium',
    analysisDone: j['analysis_done'] ?? j['analysisDone'] ?? false,
    createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at'].toString()) : null,
  );
  static int _i(dynamic v) { if (v == null) return 0; if (v is int) return v; if (v is double) return v.toInt(); return int.tryParse(v.toString()) ?? 0; }
}
