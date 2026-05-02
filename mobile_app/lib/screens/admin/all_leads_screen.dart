import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/lead.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/lead_card.dart';

class AllLeadsScreen extends StatefulWidget {
  const AllLeadsScreen({super.key});

  @override
  State<AllLeadsScreen> createState() => _AllLeadsScreenState();
}

class _AllLeadsScreenState extends State<AllLeadsScreen> {
  final _searchController = TextEditingController();
  String _status = 'all';
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLeads());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLeads() {
    return context.read<AdminProvider>().loadLeads(
          status: _status,
          search: _searchController.text,
        );
  }

  void _showLeadDetails(Lead lead) {
    final report = lead.report;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.62,
        maxChildSize: 0.9,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Text(lead.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(lead.phone, style: const TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 14),
            _DetailRow(label: 'Status', value: lead.status),
            _DetailRow(label: 'Assigned To', value: lead.assignedEmployee?.name ?? 'Unassigned'),
            if (lead.createdAt != null)
              _DetailRow(label: 'Created', value: DateFormat('dd MMM yyyy').format(lead.createdAt!)),
            const Divider(height: 28),
            if (report == null)
              const Text('No call report submitted yet', style: TextStyle(color: AppTheme.textMuted))
            else ...[
              _DetailRow(label: 'Report Status', value: report.status),
              if (report.rejectionReason.isNotEmpty)
                _DetailRow(label: 'Rejection Reason', value: report.rejectionReason),
              if (report.propertyInterest.isNotEmpty)
                _DetailRow(label: 'Property Interest', value: report.propertyInterest),
              if (report.budgetRange.isNotEmpty) _DetailRow(label: 'Budget', value: report.budgetRange),
              if (report.preferredLocation.isNotEmpty)
                _DetailRow(label: 'Preferred Location', value: report.preferredLocation),
              if (report.bhk.isNotEmpty) _DetailRow(label: 'BHK', value: report.bhk),
              if (report.desiredPlace.isNotEmpty) _DetailRow(label: 'Desired Place', value: report.desiredPlace),
              if (report.followUpDate != null)
                _DetailRow(label: 'Follow-up', value: DateFormat('dd MMM yyyy').format(report.followUpDate!)),
              if (report.notes.isNotEmpty) _DetailRow(label: 'Notes', value: report.notes),
              if (report.extraInfo.isNotEmpty) _DetailRow(label: 'Extra Info', value: report.extraInfo),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAllLeads() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('⚠️ Delete All Leads'),
        content: const Text(
          'This will permanently delete ALL leads, call reports, and upload batches. This action cannot be undone.\n\nAre you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AdminProvider>().deleteAllLeads();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All leads deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        return RefreshIndicator(
          onRefresh: _loadLeads,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _searchController,
                onSubmitted: (_) => _loadLeads(),
                decoration: InputDecoration(
                  labelText: 'Search leads',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: 'Search',
                    onPressed: _loadLeads,
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: [
                        for (final status in const ['all', 'pending', 'accepted', 'rejected'])
                          FilterChip(
                            label: Text(_labelForStatus(status)),
                            selected: _status == status,
                            onSelected: (_) {
                              setState(() => _status = status);
                              _loadLeads();
                            },
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete All Leads',
                    onPressed: admin.leads.isEmpty ? null : _deleteAllLeads,
                    icon: const Icon(Icons.delete_forever, color: AppTheme.danger),
                  ),
                ],
              ),
              if (admin.error != null) ...[
                const SizedBox(height: 12),
                Text(admin.error!, style: const TextStyle(color: AppTheme.danger)),
              ],
              const SizedBox(height: 12),
              if (admin.leads.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 50),
                  child: Center(child: Text('No leads found', style: TextStyle(color: AppTheme.textMuted))),
                )
              else
                for (final lead in admin.leads)
                  LeadCard(
                    lead: lead,
                    showEmployee: true,
                    onTap: () => _showLeadDetails(lead),
                  ),
            ],
          ),
        );
      },
    );
  }

  String _labelForStatus(String status) {
    return switch (status) {
      'all' => 'All',
      'pending' => 'Pending',
      'accepted' => 'Hot',
      'rejected' => 'Cold',
      _ => status,
    };
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value),
        ],
      ),
    );
  }
}
