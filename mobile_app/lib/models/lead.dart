import 'call_report.dart';
import 'user.dart';

class Lead {
  const Lead({
    required this.id,
    required this.name,
    required this.phone,
    required this.status,
    this.assignedToId,
    this.assignedEmployee,
    this.uploadBatchId,
    this.report,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String phone;
  final String status;
  final String? assignedToId;
  final User? assignedEmployee;
  final String? uploadBatchId;
  final CallReport? report;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';

  factory Lead.fromJson(Map<String, dynamic> json) {
    final assignedTo = json['assignedTo'];
    User? employee;
    String? employeeId;

    if (assignedTo is Map<String, dynamic>) {
      employee = User.fromJson(assignedTo);
      employeeId = employee.id;
    } else if (assignedTo != null) {
      employeeId = assignedTo.toString();
    }

    return Lead(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      assignedToId: employeeId,
      assignedEmployee: employee,
      uploadBatchId: json['uploadBatchId']?.toString(),
      report: json['report'] is Map<String, dynamic>
          ? CallReport.fromJson(json['report'] as Map<String, dynamic>)
          : null,
      createdAt: _dateFromValue(json['createdAt']),
      updatedAt: _dateFromValue(json['updatedAt']),
    );
  }

  static DateTime? _dateFromValue(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    return DateTime.tryParse(value.toString());
  }
}
