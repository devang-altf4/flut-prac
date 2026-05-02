import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/lead.dart';

class EmployeeService {
  EmployeeService({this.token});

  final String? token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> dashboard() async {
    final response = await http.get(Uri.parse(ApiConfig.employeeDashboard), headers: _headers);
    return _decodeMap(response);
  }

  Future<List<Lead>> leads({String? status}) async {
    final query = <String, String>{};
    if (status != null && status != 'all') query['status'] = status;

    final uri = Uri.parse(ApiConfig.employeeLeads).replace(queryParameters: query);
    final response = await http.get(uri, headers: _headers);
    return _decodeList(response).map((item) => Lead.fromJson(item)).toList();
  }

  Future<Lead> updateStatus(String leadId, String status) async {
    final response = await http.put(
      Uri.parse(ApiConfig.employeeLeadStatus(leadId)),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    return Lead.fromJson(_decodeMap(response));
  }

  Future<Lead> submitReport(String leadId, Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse(ApiConfig.employeeLeadReport(leadId)),
      headers: _headers,
      body: jsonEncode(payload),
    );
    final data = _decodeMap(response);
    return Lead.fromJson(data['lead'] as Map<String, dynamic>);
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw Exception(body['message'] ?? 'Request failed with ${response.statusCode}');
  }

  List<Map<String, dynamic>> _decodeList(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = response.body.isEmpty ? <dynamic>[] : jsonDecode(response.body) as List<dynamic>;
      return body.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }

    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (body is Map<String, dynamic>) {
      throw Exception(body['message'] ?? 'Request failed with ${response.statusCode}');
    }
    throw Exception('Request failed with ${response.statusCode}');
  }
}
