import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/lead.dart';
import '../../providers/employee_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'reject_lead_screen.dart';

class LeadDetailScreen extends StatefulWidget {
  const LeadDetailScreen({required this.lead, super.key});

  final Lead lead;

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _propertyController = TextEditingController();
  final _locationController = TextEditingController();
  final _desiredPlaceController = TextEditingController();
  final _notesController = TextEditingController();
  final _extraInfoController = TextEditingController();
  String _budgetRange = '50L - 1Cr';
  String _bhk = '2 BHK';
  DateTime? _followUpDate;
  bool _acceptMode = false;

  @override
  void initState() {
    super.initState();
    final report = widget.lead.report;
    if (report != null) {
      _propertyController.text = report.propertyInterest;
      _locationController.text = report.preferredLocation;
      _desiredPlaceController.text = report.desiredPlace;
      _notesController.text = report.notes;
      _extraInfoController.text = report.extraInfo;
      if (report.budgetRange.isNotEmpty) _budgetRange = report.budgetRange;
      if (report.bhk.isNotEmpty) _bhk = report.bhk;
      _followUpDate = report.followUpDate;
      _acceptMode = widget.lead.isAccepted;
    }
  }

  @override
  void dispose() {
    _propertyController.dispose();
    _locationController.dispose();
    _desiredPlaceController.dispose();
    _notesController.dispose();
    _extraInfoController.dispose();
    super.dispose();
  }

  Future<void> _callLead() async {
    final uri = Uri(scheme: 'tel', path: widget.lead.phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _pickFollowUpDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 3),
      initialDate: _followUpDate ?? now,
    );
    if (picked != null) {
      setState(() => _followUpDate = picked);
    }
  }

  Future<void> _submitAccepted() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      'status': 'accepted',
      'propertyInterest': _propertyController.text.trim(),
      'budgetRange': _budgetRange,
      'preferredLocation': _locationController.text.trim(),
      'bhk': _bhk,
      'desiredPlace': _desiredPlaceController.text.trim(),
      'followUpDate': _followUpDate?.toIso8601String(),
      'notes': _notesController.text.trim(),
      'extraInfo': _extraInfoController.text.trim(),
    };

    await context.read<EmployeeProvider>().submitReport(widget.lead.id, payload);
    if (!mounted) return;
    if (context.read<EmployeeProvider>().error == null) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EmployeeProvider>(
      builder: (context, employee, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Lead Details')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.lead.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: _callLead,
                        child: Row(
                          children: [
                            const Icon(Icons.phone, color: AppTheme.accent),
                            const SizedBox(width: 8),
                            Text(widget.lead.phone, style: const TextStyle(color: AppTheme.accent)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Chip(label: Text(widget.lead.status.toUpperCase())),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      label: 'Accept',
                      icon: Icons.thumb_up_alt_outlined,
                      backgroundColor: AppTheme.hotLead,
                      onPressed: () => setState(() => _acceptMode = true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomButton(
                      label: 'Reject',
                      icon: Icons.thumb_down_alt_outlined,
                      backgroundColor: AppTheme.coldLead,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => RejectLeadScreen(lead: widget.lead)),
                      ),
                    ),
                  ),
                ],
              ),
              if (_acceptMode) ...[
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Accepted Lead Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _propertyController,
                        label: 'Property Interest',
                        icon: Icons.home_work_outlined,
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'Enter property interest'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: _budgetRange,
                        decoration: const InputDecoration(
                          labelText: 'Budget Range',
                          prefixIcon: Icon(Icons.currency_rupee),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Below 50L', child: Text('Below 50L')),
                          DropdownMenuItem(value: '50L - 1Cr', child: Text('50L - 1Cr')),
                          DropdownMenuItem(value: '1Cr - 2Cr', child: Text('1Cr - 2Cr')),
                          DropdownMenuItem(value: '2Cr+', child: Text('2Cr+')),
                        ],
                        onChanged: (value) => setState(() => _budgetRange = value ?? _budgetRange),
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        controller: _locationController,
                        label: 'Preferred Location',
                        icon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: _bhk,
                        decoration: const InputDecoration(
                          labelText: 'BHK',
                          prefixIcon: Icon(Icons.king_bed_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: '1 BHK', child: Text('1 BHK')),
                          DropdownMenuItem(value: '2 BHK', child: Text('2 BHK')),
                          DropdownMenuItem(value: '3 BHK', child: Text('3 BHK')),
                          DropdownMenuItem(value: '4+ BHK', child: Text('4+ BHK')),
                        ],
                        onChanged: (value) => setState(() => _bhk = value ?? _bhk),
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        controller: _desiredPlaceController,
                        label: 'Desired Place',
                        icon: Icons.place_outlined,
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _pickFollowUpDate,
                        icon: const Icon(Icons.event),
                        label: Text(
                          _followUpDate == null
                              ? 'Follow-up Date'
                              : DateFormat('dd MMM yyyy').format(_followUpDate!),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        controller: _notesController,
                        label: 'Notes',
                        icon: Icons.notes_outlined,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        controller: _extraInfoController,
                        label: 'Extra Info',
                        icon: Icons.info_outline,
                        maxLines: 3,
                      ),
                      if (employee.error != null) ...[
                        const SizedBox(height: 12),
                        Text(employee.error!, style: const TextStyle(color: AppTheme.danger)),
                      ],
                      const SizedBox(height: 16),
                      CustomButton(
                        label: 'Submit Details',
                        icon: Icons.save_outlined,
                        isLoading: employee.isLoading,
                        onPressed: _submitAccepted,
                      ),
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
