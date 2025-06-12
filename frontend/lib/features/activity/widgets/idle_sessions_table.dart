import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/theme/app_colors.dart';

class IdleSessionsTable extends StatelessWidget {
  final List<dynamic> sessions;
  final Function(int) onTerminate;

  const IdleSessionsTable({
    super.key,
    required this.sessions,
    required this.onTerminate,
  });

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.info_outline,
              color: AppColors.info,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No idle sessions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Idle Sessions (${sessions.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                headingRowColor: MaterialStateProperty.all(AppColors.chipBackground),
                columns: const [
                  DataColumn(label: Text('PID')),
                  DataColumn(label: Text('User')),
                  DataColumn(label: Text('Application')),
                  DataColumn(label: Text('Client')),
                  DataColumn(label: Text('Idle For')),
                  DataColumn(label: Text('Last Query')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: sessions.map((session) {
                  final pid = session['pid'] ?? 'N/A';
                  final username = session['username'] ?? 'N/A';
                  final applicationName = session['application_name'] ?? 'N/A';
                  final clientAddress = session['client_address'] ?? 'N/A';
                  final idleDuration = session['idle_duration_seconds'] ?? 0;
                  final query = session['query'] ?? 'N/A';
                  
                  // Calculate idle duration text
                  final idleStart = DateTime.now().subtract(
                    Duration(seconds: idleDuration.toInt()),
                  );
                  final idleText = timeago.format(idleStart, allowFromNow: true);
                  
                  return DataRow(
                    cells: [
                      DataCell(Text(pid.toString())),
                      DataCell(Text(username.toString())),
                      DataCell(Text(applicationName.toString())),
                      DataCell(Text(clientAddress.toString())),
                      DataCell(Text(idleText)),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: Text(
                            query.toString(),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.error, size: 20),
                          tooltip: 'Terminate Session',
                          onPressed: () => onTerminate(pid),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}