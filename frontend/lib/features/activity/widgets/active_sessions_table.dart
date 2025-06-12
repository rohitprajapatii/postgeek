import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/theme/app_colors.dart';

class ActiveSessionsTable extends StatelessWidget {
  final List<dynamic> sessions;
  final Function(int) onTerminate;

  const ActiveSessionsTable({
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
              'No active sessions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _buildSessionCard(context, session);
      },
    );
  }

  Widget _buildSessionCard(BuildContext context, dynamic session) {
    final pid = session['pid'] ?? 'N/A';
    final username = session['username'] ?? 'N/A';
    final applicationName = session['application_name'] ?? 'N/A';
    final clientAddress = session['client_address'] ?? 'N/A';
    final state = session['state'] ?? 'N/A';
    final queryDuration = session['query_duration_seconds'] ?? 0;
    final query = session['query'] ?? 'N/A';
    final waitEventType = session['wait_event_type'] ?? 'N/A';
    final waitEvent = session['wait_event'] ?? 'N/A';
    
    // Calculate duration ago text
    final queryStart = DateTime.now().subtract(
      Duration(seconds: queryDuration.toInt()),
    );
    final durationText = timeago.format(queryStart, allowFromNow: true);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            title: Row(
              children: [
                Text('PID: $pid'),
                const SizedBox(width: 16),
                _buildStateChip(state),
              ],
            ),
            subtitle: Text('User: $username, App: $applicationName, Client: $clientAddress'),
            trailing: IconButton(
              icon: const Icon(Icons.close, color: AppColors.error),
              tooltip: 'Terminate Session',
              onPressed: () => onTerminate(pid),
            ),
          ),
          
          // Query section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Query details
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Running for: $durationText',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: _getDurationColor(queryDuration),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (waitEventType != 'N/A')
                            Text(
                              'Waiting on: $waitEventType ($waitEvent)',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // SQL query display
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFF282C34),
                  ),
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: HighlightView(
                      _formatQuery(query),
                      language: 'sql',
                      theme: atomOneDarkTheme,
                      padding: const EdgeInsets.all(12),
                      textStyle: const TextStyle(
                        fontFamily: 'Fira Code',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateChip(String state) {
    Color color;
    
    switch (state.toLowerCase()) {
      case 'active':
        color = AppColors.success;
        break;
      case 'idle':
        color = AppColors.info;
        break;
      case 'idle in transaction':
        color = AppColors.warning;
        break;
      case 'waiting':
        color = AppColors.secondary;
        break;
      default:
        color = AppColors.textSecondary;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        state,
        style: TextStyle(
          fontSize: 12,
          color: color,
        ),
      ),
    );
  }

  Color _getDurationColor(double seconds) {
    if (seconds < 10) {
      return AppColors.success;
    } else if (seconds < 60) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }

  String _formatQuery(String query) {
    // Simple SQL formatting for display
    // In a real app, you'd use a more sophisticated SQL formatter
    return query
        .replaceAll(' FROM ', '\nFROM ')
        .replaceAll(' WHERE ', '\nWHERE ')
        .replaceAll(' AND ', '\nAND ')
        .replaceAll(' OR ', '\nOR ')
        .replaceAll(' GROUP BY ', '\nGROUP BY ')
        .replaceAll(' ORDER BY ', '\nORDER BY ')
        .replaceAll(' LIMIT ', '\nLIMIT ');
  }
}