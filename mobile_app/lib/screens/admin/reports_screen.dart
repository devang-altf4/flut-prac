import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../services/report_save_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/permission_dialogs.dart';
import '../../widgets/stat_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportSaveService _saver = ReportSaveService();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDashboard();
    });
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
    }
  }

  Future<void> _download() async {
    final tempPath = await context
        .read<AdminProvider>()
        .prepareReport(startDate: _startDate, endDate: _endDate);
    if (tempPath == null || !mounted) return;

    final destination = await _showDestinationSheet();
    if (destination == null || !mounted) return;

    if (destination == SaveDestination.downloads &&
        await _saver.needsLegacyStoragePermission()) {
      if (!mounted) return;
      final consent = await showStoragePermissionRationale(context);
      if (!consent || !mounted) return;
    }

    await _runSave(tempPath, destination);
  }

  Future<void> _runSave(String tempPath, SaveDestination destination) async {
    try {
      final result = await _saver.save(
        tempFilePath: tempPath,
        destination: destination,
      );
      if (result == null || !mounted) return;

      context.read<AdminProvider>().setLastReportPath(result.displayPath);

      final open = await OpenFilex.open(result.openTarget);
      if (!mounted) return;
      if (open.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Saved to ${result.displayPath}, but could not open: ${open.message}',
            ),
          ),
        );
      }
    } on PermissionDeniedException catch (e) {
      if (!mounted) return;
      if (e.permanentlyDenied) {
        final goToSettings = await showOpenSettingsDialog(context);
        if (goToSettings) {
          await _saver.openSettings();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission denied. Cannot save the report.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save report: $e')),
      );
    }
  }

  Future<SaveDestination?> _showDestinationSheet() {
    return showModalBottomSheet<SaveDestination>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Save report as',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Save to Downloads'),
              subtitle: const Text('Default location, opens automatically'),
              onTap: () =>
                  Navigator.pop(sheetContext, SaveDestination.downloads),
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('Choose location…'),
              subtitle: const Text('Pick a custom folder'),
              onTap: () => Navigator.pop(sheetContext, SaveDestination.custom),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final dashboard = admin.dashboard;
        final formatter = DateFormat('dd MMM yyyy');
        final rangeLabel = _startDate == null || _endDate == null
            ? 'All time'
            : '${formatter.format(_startDate!)} - ${formatter.format(_endDate!)}';

        return RefreshIndicator(
          onRefresh: admin.loadDashboard,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Reports',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                rangeLabel,
                style: const TextStyle(color: AppTheme.textMuted),
              ),
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
                    title: 'Pending',
                    value: '${dashboard['pending'] ?? 0}',
                    icon: Icons.pending_actions,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: _pickRange,
                icon: const Icon(Icons.date_range),
                label: const Text('Choose Date Range'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CustomButton(
                label: 'Download PDF',
                icon: Icons.picture_as_pdf_outlined,
                isLoading: admin.isLoading,
                onPressed: _download,
              ),
              if (admin.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  admin.error!,
                  style: const TextStyle(color: AppTheme.danger),
                ),
              ],
              if (admin.lastReportPath != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Saved to ${admin.lastReportPath}',
                  style: const TextStyle(color: AppTheme.success),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Per-Employee Breakdown',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              for (final item
                  in (dashboard['employeeStats'] as List<dynamic>? ?? []))
                Card(
                  child: ListTile(
                    title: Text(item['name']?.toString() ?? 'Employee'),
                    subtitle: Text(
                      'Assigned ${item['assigned'] ?? 0} | Hot ${item['accepted'] ?? 0} | Cold ${item['rejected'] ?? 0} | Pending ${item['pending'] ?? 0}',
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
