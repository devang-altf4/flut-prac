import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/stat_card.dart';
import '../login_screen.dart';
import 'all_leads_screen.dart';
import 'manage_employees.dart';
import 'reports_screen.dart';
import 'upload_leads.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({this.initialIndex = 0, super.key});

  final int initialIndex;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late int _index = widget.initialIndex;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminProvider>();
      admin.loadDashboard();
      admin.loadEmployees();
    });
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _AdminHome(onNavigate: (index) => setState(() => _index = index)),
      const ManageEmployeesScreen(),
      const AllLeadsScreen(),
      const ReportsScreen(),
    ];

    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        return LoadingOverlay(
          isLoading: admin.isLoading,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Admin Dashboard'),
              actions: [
                IconButton(
                  tooltip: 'Logout',
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
            body: pages[_index],
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _index,
              onTap: (value) => setState(() => _index = value),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
                BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'Employees'),
                BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), label: 'Leads'),
                BottomNavigationBarItem(icon: Icon(Icons.picture_as_pdf_outlined), label: 'Reports'),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AdminHome extends StatelessWidget {
  const _AdminHome({required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final admin = context.watch<AdminProvider>();
    final dashboard = admin.dashboard;
    final employeeStats = (dashboard['employeeStats'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    return RefreshIndicator(
      onRefresh: admin.loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Welcome, ${auth.user?.name ?? 'Admin'}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text('Monitor lead status and team performance.', style: TextStyle(color: AppTheme.textMuted)),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width > 640 ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.22,
            children: [
              StatCard(
                title: 'Total Leads',
                value: '${dashboard['totalLeads'] ?? 0}',
                icon: Icons.contacts_outlined,
                color: AppTheme.primary,
              ),
              StatCard(
                title: 'Hot Leads',
                value: '${dashboard['accepted'] ?? 0}',
                icon: Icons.local_fire_department_outlined,
                color: AppTheme.hotLead,
              ),
              StatCard(
                title: 'Cold Leads',
                value: '${dashboard['rejected'] ?? 0}',
                icon: Icons.ac_unit_outlined,
                color: AppTheme.coldLead,
              ),
              StatCard(
                title: 'Pending Leads',
                value: '${dashboard['pending'] ?? 0}',
                icon: Icons.pending_actions_outlined,
                color: AppTheme.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 180,
                child: CustomButton(
                  label: 'Upload Leads',
                  icon: Icons.upload_file,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UploadLeadsScreen()),
                  ),
                ),
              ),
              SizedBox(
                width: 180,
                child: CustomButton(
                  label: 'Add Employee',
                  icon: Icons.person_add_alt,
                  onPressed: () => onNavigate(1),
                ),
              ),
              SizedBox(
                width: 190,
                child: CustomButton(
                  label: 'Download Report',
                  icon: Icons.download,
                  onPressed: () => onNavigate(3),
                  backgroundColor: AppTheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Employee Performance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Container(
            height: 260,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: employeeStats.isEmpty
                ? const Center(
                    child: Text('No employee data yet', style: TextStyle(color: AppTheme.textMuted)),
                  )
                : BarChart(
                    BarChartData(
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= employeeStats.length) {
                                return const SizedBox.shrink();
                              }
                              final name = employeeStats[index]['name']?.toString() ?? '';
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  name.length > 7 ? name.substring(0, 7) : name,
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < employeeStats.length; i += 1)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: (employeeStats[i]['accepted'] as num? ?? 0).toDouble(),
                                color: AppTheme.hotLead,
                                width: 10,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              BarChartRodData(
                                toY: (employeeStats[i]['rejected'] as num? ?? 0).toDouble(),
                                color: AppTheme.coldLead,
                                width: 10,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
