import 'package:flutter/foundation.dart';

import '../models/lead.dart';
import '../models/user.dart';
import '../services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  AdminService _service = AdminService();

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _dashboard = {};
  List<User> _employees = [];
  List<Lead> _leads = [];
  Map<String, dynamic>? _lastDistribution;
  String? _lastReportPath;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get dashboard => _dashboard;
  List<User> get employees => _employees;
  List<Lead> get leads => _leads;
  Map<String, dynamic>? get lastDistribution => _lastDistribution;
  String? get lastReportPath => _lastReportPath;

  void updateToken(String? token) {
    _service = AdminService(token: token);
  }

  Future<void> loadDashboard() async {
    await _run(() async {
      _dashboard = await _service.dashboard();
    });
  }

  Future<void> loadEmployees() async {
    await _run(() async {
      _employees = await _service.employees();
    });
  }

  Future<void> createEmployee({
    required String name,
    required String username,
    required String password,
  }) async {
    await _run(() async {
      await _service.createEmployee(name: name, username: username, password: password);
      _employees = await _service.employees();
      _dashboard = await _service.dashboard();
    });
  }

  Future<void> deactivateEmployee(String id) async {
    await _run(() async {
      await _service.deactivateEmployee(id);
      _employees = await _service.employees();
      _dashboard = await _service.dashboard();
    });
  }

  Future<void> uploadLeads(String filePath) async {
    await _run(() async {
      final result = await _service.uploadLeads(filePath);
      _lastDistribution = result['distribution'] as Map<String, dynamic>?;
      _dashboard = await _service.dashboard();
    });
  }

  Future<void> loadLeads({String status = 'all', String? search, String? employeeId}) async {
    await _run(() async {
      _leads = await _service.leads(status: status, search: search, employeeId: employeeId);
    });
  }

  Future<void> downloadReport({DateTime? startDate, DateTime? endDate}) async {
    await _run(() async {
      _lastReportPath = await _service.downloadReport(startDate: startDate, endDate: endDate);
    });
  }

  Future<void> deleteAllLeads() async {
    await _run(() async {
      await _service.deleteAllLeads();
      _leads = [];
      _dashboard = await _service.dashboard();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await action();
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
