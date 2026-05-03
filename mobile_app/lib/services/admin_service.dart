import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:media_store_plus/media_store_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config/api_config.dart';
import '../models/lead.dart';
import '../models/user.dart';

class AdminService {
  AdminService({this.token});

  final String? token;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  Future<Map<String, dynamic>> dashboard() async {
    final response = await http.get(
      Uri.parse(ApiConfig.adminDashboard),
      headers: _headers,
    );
    return _decodeMap(response);
  }

  Future<List<User>> employees() async {
    final response = await http.get(
      Uri.parse(ApiConfig.adminEmployees),
      headers: _headers,
    );
    final data = _decodeList(response);
    return data.map((item) => User.fromJson(item)).toList();
  }

  Future<User> createEmployee({
    required String name,
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.adminEmployees),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'username': username,
        'password': password,
      }),
    );
    return User.fromJson(_decodeMap(response));
  }

  Future<void> deactivateEmployee(String id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.adminEmployees}/$id'),
      headers: _headers,
    );
    _decodeMap(response);
  }

  Future<Map<String, dynamic>> uploadLeads(String filePath) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConfig.adminUploadLeads),
    );
    if (token != null && token!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _decodeMap(response);
  }

  Future<List<Lead>> leads({
    String? status,
    String? employeeId,
    String? batchId,
    String? search,
  }) async {
    final query = <String, String>{};
    if (status != null && status != 'all') query['status'] = status;
    if (employeeId != null && employeeId.isNotEmpty)
      query['employeeId'] = employeeId;
    if (batchId != null && batchId.isNotEmpty) query['batchId'] = batchId;
    if (search != null && search.trim().isNotEmpty)
      query['search'] = search.trim();

    final uri = Uri.parse(ApiConfig.adminLeads).replace(queryParameters: query);
    final response = await http.get(uri, headers: _headers);
    return _decodeList(response).map((item) => Lead.fromJson(item)).toList();
  }

  Future<String> downloadReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final query = <String, String>{};
    if (startDate != null) query['startDate'] = startDate.toIso8601String();
    if (endDate != null) query['endDate'] = endDate.toIso8601String();

    final uri = Uri.parse(
      ApiConfig.adminReportDownload,
    ).replace(queryParameters: query);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = response.body.isEmpty
          ? 'Report download failed'
          : response.body;
      throw Exception(message);
    }

    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/dayaar_crm_report.pdf');
    await tempFile.writeAsBytes(response.bodyBytes);

    String displayPath;
    String openPath;

    if (Platform.isAndroid) {
      if (await _needsLegacyStoragePermission()) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          await openAppSettings();
          throw Exception('Storage permission denied');
        }
      }
      await MediaStore.ensureInitialized();
      MediaStore.appFolder = 'DayaarCRM';
      final info = await MediaStore().saveFile(
        tempFilePath: tempFile.path,
        dirType: DirType.download,
        dirName: DirName.download,
      );
      if (info == null || info.uri.toString().isEmpty) {
        throw Exception('Failed to save report to Downloads');
      }
      openPath = info.uri.toString();
      displayPath = 'Download/dayaar_crm_report.pdf';
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/dayaar_crm_report.pdf');
      await file.writeAsBytes(response.bodyBytes);
      openPath = file.path;
      displayPath = file.path;
    }

    final result = await OpenFilex.open(openPath);
    if (result.type != ResultType.done) {
      // Non-fatal: the report is already saved for manual opening.
    }

    return displayPath;
  }

  Future<bool> _needsLegacyStoragePermission() async {
    if (!Platform.isAndroid) return false;
    final info = await DeviceInfoPlugin().androidInfo;
    return info.version.sdkInt <= 28;
  }

  Future<Map<String, dynamic>> deleteAllLeads() async {
    final response = await http.delete(
      Uri.parse(ApiConfig.adminDeleteAllLeads),
      headers: _headers,
    );
    return _decodeMap(response);
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw Exception(
      body['message'] ?? 'Request failed with ${response.statusCode}',
    );
  }

  List<Map<String, dynamic>> _decodeList(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = response.body.isEmpty
          ? <dynamic>[]
          : jsonDecode(response.body) as List<dynamic>;
      return body
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (body is Map<String, dynamic>) {
      throw Exception(
        body['message'] ?? 'Request failed with ${response.statusCode}',
      );
    }
    throw Exception('Request failed with ${response.statusCode}');
  }
}
