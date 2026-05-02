import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';

class UploadLeadsScreen extends StatefulWidget {
  const UploadLeadsScreen({super.key});

  @override
  State<UploadLeadsScreen> createState() => _UploadLeadsScreenState();
}

class _UploadLeadsScreenState extends State<UploadLeadsScreen> {
  PlatformFile? _file;
  List<String> _previewRows = [];

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final preview = await _buildPreview(file);
    setState(() {
      _file = file;
      _previewRows = preview;
    });
  }

  Future<List<String>> _buildPreview(PlatformFile file) async {
    final path = file.path;
    if (path == null) return ['${file.name} selected'];
    final extension = file.extension?.toLowerCase();

    if (extension == 'csv') {
      final lines = await File(path).readAsLines();
      return lines.take(5).toList();
    }

    return [
      '${file.name} selected',
      'Excel file will be parsed as Name + Phone Number on upload.',
    ];
  }

  Future<void> _upload() async {
    final path = _file?.path;
    if (path == null) return;
    await context.read<AdminProvider>().uploadLeads(path);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final distribution = admin.lastDistribution;

        return Scaffold(
          appBar: AppBar(title: const Text('Upload Leads')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'CSV or Excel Upload',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Files are parsed as two columns: Name and Phone Number.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file),
                label: Text(_file == null ? 'Choose CSV/Excel file' : _file!.name),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              if (_previewRows.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  'Preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final row in _previewRows)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(row, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                  ),
                ),
              ],
              if (admin.error != null) ...[
                const SizedBox(height: 14),
                Text(admin.error!, style: const TextStyle(color: AppTheme.danger)),
              ],
              const SizedBox(height: 18),
              CustomButton(
                label: 'Upload and Distribute',
                icon: Icons.cloud_upload_outlined,
                isLoading: admin.isLoading,
                onPressed: _file == null ? null : _upload,
              ),
              if (distribution != null) ...[
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.success.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Distribution Summary',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(distribution['message']?.toString() ?? 'Upload complete'),
                      const SizedBox(height: 8),
                      Text('Total leads: ${distribution['totalLeads'] ?? 0}'),
                      Text('Employees: ${distribution['employeeCount'] ?? 0}'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
