import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/lead.dart';
import '../../providers/employee_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class RejectLeadScreen extends StatefulWidget {
  const RejectLeadScreen({required this.lead, super.key});

  final Lead lead;

  @override
  State<RejectLeadScreen> createState() => _RejectLeadScreenState();
}

class _RejectLeadScreenState extends State<RejectLeadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final report = widget.lead.report;
    if (report != null) {
      _reasonController.text = report.rejectionReason;
      _notesController.text = report.notes;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await context.read<EmployeeProvider>().submitReport(widget.lead.id, {
      'status': 'rejected',
      'rejectionReason': _reasonController.text.trim(),
      'notes': _notesController.text.trim(),
    });

    if (!mounted) return;
    if (context.read<EmployeeProvider>().error == null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EmployeeProvider>(
      builder: (context, employee, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Reject Lead')),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.lead.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(widget.lead.phone, style: const TextStyle(color: AppTheme.textMuted)),
                const SizedBox(height: 18),
                CustomTextField(
                  controller: _reasonController,
                  label: 'Rejection Reason',
                  icon: Icons.report_problem_outlined,
                  maxLines: 4,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter rejection reason'
                      : null,
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  controller: _notesController,
                  label: 'Notes',
                  icon: Icons.notes_outlined,
                  maxLines: 3,
                ),
                if (employee.error != null) ...[
                  const SizedBox(height: 12),
                  Text(employee.error!, style: const TextStyle(color: AppTheme.danger)),
                ],
                const SizedBox(height: 16),
                CustomButton(
                  label: 'Submit Rejection',
                  icon: Icons.save_outlined,
                  isLoading: employee.isLoading,
                  backgroundColor: AppTheme.coldLead,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
