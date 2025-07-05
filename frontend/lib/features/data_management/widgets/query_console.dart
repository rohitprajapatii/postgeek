import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/data_management_bloc.dart';
import '../models/table_data.dart';

class QueryConsole extends StatefulWidget {
  const QueryConsole({super.key});

  @override
  State<QueryConsole> createState() => _QueryConsoleState();
}

class _QueryConsoleState extends State<QueryConsole> {
  final TextEditingController _queryController = TextEditingController();
  bool _isReadonly = true;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Query Input Area
        Expanded(
          flex: 2,
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'SQL Query',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Checkbox(
                            value: _isReadonly,
                            onChanged: (value) {
                              setState(() {
                                _isReadonly = value ?? true;
                              });
                            },
                          ),
                          const Text('Read-only'),
                        ],
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _executeQuery,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Execute'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        hintText:
                            'Enter your SQL query here...\n\nExample:\nSELECT * FROM users LIMIT 10;',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(
                        fontFamily: 'Courier New',
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Results Area
        Expanded(
          flex: 3,
          child: Card(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Query Results',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: BlocBuilder<DataManagementBloc, DataManagementState>(
                      builder: (context, state) {
                        if (state.status == DataManagementStatus.loading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (state.queryResult == null) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.code,
                                  size: 48,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No query executed yet',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.7),
                                      ),
                                ),
                              ],
                            ),
                          );
                        }

                        return _buildQueryResults(context, state.queryResult!);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQueryResults(BuildContext context, QueryResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results Info
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                '${result.rowCount} rows returned',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              Text(
                'Execution time: ${result.executionTime}ms',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Results Table
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: result.rows.isEmpty
                  ? Center(
                      child: Text(
                        'No data returned',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    )
                  : DataTable(
                      columns: result.fields
                          .map((field) => DataColumn(
                                label: Text(
                                  field.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ))
                          .toList(),
                      rows: result.rows
                          .map((row) => DataRow(
                                cells: result.fields
                                    .map((field) => DataCell(
                                          Text(
                                            row[field.name]?.toString() ??
                                                'NULL',
                                            style: row[field.name] == null
                                                ? TextStyle(
                                                    fontStyle: FontStyle.italic,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.5),
                                                  )
                                                : null,
                                          ),
                                        ))
                                    .toList(),
                              ))
                          .toList(),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  void _executeQuery() {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a query'),
        ),
      );
      return;
    }

    // context.read<DataManagementBloc>().add(ExecuteQuery(query, _isReadonly));
  }
}
