class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000/api',
  );

  static const String login = '$baseUrl/auth/login';
  static const String adminDashboard = '$baseUrl/admin/dashboard';
  static const String adminEmployees = '$baseUrl/admin/employees';
  static const String adminUploadLeads = '$baseUrl/admin/upload-leads';
  static const String adminLeads = '$baseUrl/admin/leads';
  static const String adminReportDownload = '$baseUrl/admin/reports/download';
  static const String adminDeleteAllLeads = '$baseUrl/admin/leads';
  static const String employeeDashboard = '$baseUrl/employee/dashboard';
  static const String employeeLeads = '$baseUrl/employee/leads';

  static String employeeLeadStatus(String id) => '$baseUrl/employee/leads/$id/status';
  static String employeeLeadReport(String id) => '$baseUrl/employee/leads/$id/report';
}
