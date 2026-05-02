import 'package:flutter/foundation.dart';

import '../models/lead.dart';
import '../services/employee_service.dart';

class EmployeeProvider extends ChangeNotifier {
  EmployeeService _service = EmployeeService();

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _dashboard = {};
  List<Lead> _leads = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get dashboard => _dashboard;
  List<Lead> get leads => _leads;
  List<Lead> get pendingLeads => _leads.where((lead) => lead.isPending).toList();
  List<Lead> get hotLeads => _leads.where((lead) => lead.isAccepted).toList();
  List<Lead> get coldLeads => _leads.where((lead) => lead.isRejected).toList();

  void updateToken(String? token) {
    _service = EmployeeService(token: token);
  }

  Future<void> loadDashboard() async {
    await _run(() async {
      _dashboard = await _service.dashboard();
    });
  }

  Future<void> loadLeads({String status = 'all'}) async {
    await _run(() async {
      _leads = await _service.leads(status: status);
    });
  }

  Future<void> refreshAll() async {
    await _run(() async {
      _dashboard = await _service.dashboard();
      _leads = await _service.leads();
    });
  }

  Future<void> updateStatus(String leadId, String status) async {
    await _run(() async {
      await _service.updateStatus(leadId, status);
      _dashboard = await _service.dashboard();
      _leads = await _service.leads();
    });
  }

  Future<void> submitReport(String leadId, Map<String, dynamic> payload) async {
    await _run(() async {
      await _service.submitReport(leadId, payload);
      _dashboard = await _service.dashboard();
      _leads = await _service.leads();
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
