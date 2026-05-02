import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/employee_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/lead_card.dart';
import 'lead_detail_screen.dart';

class ColdLeadsScreen extends StatefulWidget {
  const ColdLeadsScreen({super.key});

  @override
  State<ColdLeadsScreen> createState() => _ColdLeadsScreenState();
}

class _ColdLeadsScreenState extends State<ColdLeadsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().loadLeads(status: 'rejected');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EmployeeProvider>(
      builder: (context, employee, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Cold Leads ❄️')),
          body: RefreshIndicator(
            onRefresh: () => employee.loadLeads(status: 'rejected'),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (employee.error != null)
                  Text(employee.error!, style: const TextStyle(color: AppTheme.danger)),
                if (employee.leads.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: Center(child: Text('No cold leads yet', style: TextStyle(color: AppTheme.textMuted))),
                  )
                else
                  for (final lead in employee.leads)
                    LeadCard(
                      lead: lead,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => LeadDetailScreen(lead: lead)),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}
