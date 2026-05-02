import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/lead.dart';
import '../../providers/auth_provider.dart';
import '../../providers/employee_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/lead_card.dart';
import '../login_screen.dart';
import 'cold_leads_screen.dart';
import 'hot_leads_screen.dart';
import 'lead_detail_screen.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().refreshAll();
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

  void _openLead(Lead lead) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => LeadDetailScreen(lead: lead)));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, EmployeeProvider>(
      builder: (context, auth, employee, _) {
        final dashboard = employee.dashboard;
        final total = dashboard['totalAssigned'] as int? ?? 0;
        final completed = (dashboard['accepted'] as int? ?? 0) + (dashboard['rejected'] as int? ?? 0);
        final progress = total == 0 ? 0.0 : completed / total;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Employee Dashboard'),
            actions: [
              IconButton(
                tooltip: 'Logout',
                onPressed: _logout,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: employee.refreshAll,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Welcome, ${auth.user?.name ?? dashboard['name'] ?? 'Employee'}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completed of $total leads processed',
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: AppTheme.surface,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _SectionCard(
                        title: 'Hot Leads 🔥',
                        count: dashboard['accepted'] as int? ?? employee.hotLeads.length,
                        icon: Icons.local_fire_department,
                        colors: const [AppTheme.hotLead, Color(0xFFB83216)],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HotLeadsScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SectionCard(
                        title: 'Cold Leads ❄️',
                        count: dashboard['rejected'] as int? ?? employee.coldLeads.length,
                        icon: Icons.ac_unit,
                        colors: const [AppTheme.coldLead, AppTheme.secondary],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ColdLeadsScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  'Pending Leads (${dashboard['pending'] ?? employee.pendingLeads.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                if (employee.error != null)
                  Text(employee.error!, style: const TextStyle(color: AppTheme.danger)),
                if (employee.isLoading && employee.leads.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (employee.pendingLeads.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: Text('No pending leads', style: TextStyle(color: AppTheme.textMuted))),
                  )
                else
                  for (final lead in employee.pendingLeads) LeadCard(lead: lead, onTap: () => _openLead(lead)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String title;
  final int count;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
