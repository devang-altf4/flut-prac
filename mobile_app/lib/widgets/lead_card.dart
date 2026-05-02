import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/lead.dart';
import '../theme/app_theme.dart';

class LeadCard extends StatelessWidget {
  const LeadCard({
    required this.lead,
    this.onTap,
    this.showEmployee = false,
    super.key,
  });

  final Lead lead;
  final VoidCallback? onTap;
  final bool showEmployee;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (lead.status) {
      'accepted' => AppTheme.hotLead,
      'rejected' => AppTheme.coldLead,
      _ => AppTheme.textMuted,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lead.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  _StatusBadge(status: lead.status, color: statusColor),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 16, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Text(lead.phone, style: const TextStyle(color: AppTheme.textMuted)),
                ],
              ),
              if (showEmployee) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: AppTheme.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        lead.assignedEmployee?.name ?? 'Unassigned',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                  ],
                ),
              ],
              if (lead.report != null && lead.isAccepted) ...[
                const SizedBox(height: 10),
                Text(
                  [
                    if (lead.report!.propertyInterest.isNotEmpty) lead.report!.propertyInterest,
                    if (lead.report!.budgetRange.isNotEmpty) lead.report!.budgetRange,
                    if (lead.report!.followUpDate != null)
                      'Follow-up ${DateFormat('dd MMM').format(lead.report!.followUpDate!)}',
                  ].join(' | '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
              if (lead.report != null && lead.isRejected) ...[
                const SizedBox(height: 10),
                Text(
                  lead.report!.rejectionReason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
