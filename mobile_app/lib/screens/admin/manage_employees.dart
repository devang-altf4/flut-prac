import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ManageEmployeesScreen extends StatefulWidget {
  const ManageEmployeesScreen({super.key});

  @override
  State<ManageEmployeesScreen> createState() => _ManageEmployeesScreenState();
}

class _ManageEmployeesScreenState extends State<ManageEmployeesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadEmployees();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createEmployee() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AdminProvider>().createEmployee(
          name: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );
    if (!mounted) return;
    if (context.read<AdminProvider>().error == null) {
      _nameController.clear();
      _usernameController.clear();
      _passwordController.clear();
    }
  }

  Future<bool> _confirmDeactivate(User employee) async {
    if (!employee.isActive) return false;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate employee?'),
        content: Text('Pending leads for ${employee.name} will be redistributed.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Deactivate')),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AdminProvider>().deactivateEmployee(employee.id);
    }
    return false;
  }

  void _showEmployeeStats(User employee) {
    final stats = employee.stats ?? {};
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(employee.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(employee.username, style: const TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _MiniStat(label: 'Assigned', value: '${stats['totalAssigned'] ?? 0}'),
                _MiniStat(label: 'Hot', value: '${stats['accepted'] ?? 0}'),
                _MiniStat(label: 'Cold', value: '${stats['rejected'] ?? 0}'),
                _MiniStat(label: 'Pending', value: '${stats['pending'] ?? 0}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        return RefreshIndicator(
          onRefresh: admin.loadEmployees,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create Employee',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _nameController,
                      label: 'Name',
                      icon: Icons.badge_outlined,
                      validator: (value) => value == null || value.trim().isEmpty ? 'Enter name' : null,
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: _usernameController,
                      label: 'Username',
                      icon: Icons.person_outline,
                      validator: (value) => value == null || value.trim().isEmpty ? 'Enter username' : null,
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: true,
                      validator: (value) => value == null || value.length < 6 ? 'Minimum 6 characters' : null,
                    ),
                    if (admin.error != null) ...[
                      const SizedBox(height: 10),
                      Text(admin.error!, style: const TextStyle(color: AppTheme.danger)),
                    ],
                    const SizedBox(height: 14),
                    CustomButton(
                      label: 'Create Employee',
                      icon: Icons.person_add_alt,
                      isLoading: admin.isLoading,
                      onPressed: _createEmployee,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Text(
                'Employees',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              if (admin.employees.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text('No employees yet', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                )
              else
                for (final employee in admin.employees)
                  Dismissible(
                    key: ValueKey(employee.id),
                    direction: employee.isActive ? DismissDirection.endToStart : DismissDirection.none,
                    confirmDismiss: (_) => _confirmDeactivate(employee),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 18),
                      color: AppTheme.danger,
                      child: const Icon(Icons.block, color: Colors.white),
                    ),
                    child: Card(
                      child: ListTile(
                        onTap: () => _showEmployeeStats(employee),
                        leading: CircleAvatar(
                          backgroundColor: employee.isActive ? AppTheme.primary : AppTheme.textMuted,
                          child: Text(employee.name.isEmpty ? '?' : employee.name[0].toUpperCase()),
                        ),
                        title: Text(employee.name),
                        subtitle: Text(employee.username),
                        trailing: Chip(
                          label: Text(employee.isActive ? 'Active' : 'Inactive'),
                          backgroundColor: employee.isActive
                              ? AppTheme.success.withValues(alpha: 0.15)
                              : AppTheme.textMuted.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}
