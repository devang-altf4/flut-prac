class CallReport {
  const CallReport({
    required this.id,
    required this.leadId,
    required this.employeeId,
    required this.status,
    this.rejectionReason = '',
    this.propertyInterest = '',
    this.budgetRange = '',
    this.preferredLocation = '',
    this.bhk = '',
    this.desiredPlace = '',
    this.followUpDate,
    this.notes = '',
    this.extraInfo = '',
    this.createdAt,
  });

  final String id;
  final String leadId;
  final String employeeId;
  final String status;
  final String rejectionReason;
  final String propertyInterest;
  final String budgetRange;
  final String preferredLocation;
  final String bhk;
  final String desiredPlace;
  final DateTime? followUpDate;
  final String notes;
  final String extraInfo;
  final DateTime? createdAt;

  factory CallReport.fromJson(Map<String, dynamic> json) {
    return CallReport(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      leadId: _idFromValue(json['leadId']),
      employeeId: _idFromValue(json['employeeId']),
      status: (json['status'] ?? '').toString(),
      rejectionReason: (json['rejectionReason'] ?? '').toString(),
      propertyInterest: (json['propertyInterest'] ?? '').toString(),
      budgetRange: (json['budgetRange'] ?? '').toString(),
      preferredLocation: (json['preferredLocation'] ?? '').toString(),
      bhk: (json['bhk'] ?? '').toString(),
      desiredPlace: (json['desiredPlace'] ?? '').toString(),
      followUpDate: _dateFromValue(json['followUpDate']),
      notes: (json['notes'] ?? '').toString(),
      extraInfo: (json['extraInfo'] ?? '').toString(),
      createdAt: _dateFromValue(json['createdAt']),
    );
  }

  static String _idFromValue(dynamic value) {
    if (value is Map<String, dynamic>) {
      return (value['_id'] ?? value['id'] ?? '').toString();
    }
    return (value ?? '').toString();
  }

  static DateTime? _dateFromValue(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    return DateTime.tryParse(value.toString());
  }
}
