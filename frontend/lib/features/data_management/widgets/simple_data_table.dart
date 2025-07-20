import 'package:flutter/material.dart';

import '../models/table_data.dart';
import '../models/table_details.dart';

class SimpleDataTable extends StatelessWidget {
  final TableDetails tableDetails;
  final PaginatedTableData tableData;
  final Function(Map<String, dynamic>) onEditRecord;
  final Function(Map<String, dynamic>) onDeleteRecord;

  const SimpleDataTable({
    super.key,
    required this.tableDetails,
    required this.tableData,
    required this.onEditRecord,
    required this.onDeleteRecord,
  });

  @override
  Widget build(BuildContext context) {
    if (tableData.data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_view_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No data available',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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

    return Column(
      children: [
        // Pagination Info
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Showing ${(tableData.pagination.page - 1) * tableData.pagination.limit + 1}-'
                '${((tableData.pagination.page - 1) * tableData.pagination.limit + tableData.data.length).clamp(0, tableData.pagination.total)} '
                'of ${tableData.pagination.total} records',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              Text(
                'Page ${tableData.pagination.page} of ${tableData.pagination.totalPages}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),

        // Data Table
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: [
                  // Add action column
                  const DataColumn(
                    label: Text(
                      'Actions',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Add data columns
                  ...tableDetails.columns.map((column) => DataColumn(
                        label: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  column.columnName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (column.isPrimaryKey)
                                  const Icon(
                                    Icons.key,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                if (column.isForeignKey)
                                  const Icon(
                                    Icons.link,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                              ],
                            ),
                            Text(
                              column.dataType,
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
                rows: tableData.data.map((record) {
                  return DataRow(
                    cells: [
                      // Action cell
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 16),
                              onPressed: () => onEditRecord(record.data),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 16),
                              onPressed: () => onDeleteRecord(record.data),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ),
                      // Data cells
                      ...tableDetails.columns.map((column) {
                                                  final value = record.data[column.columnName];
                          return DataCell(
                            Text(
                              value?.toString() ?? 'NULL',
                              style: value == null
                                  ? TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.5),
                                    )
                                  : null,
                            ),
                          );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),

        // Pagination Controls
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: tableData.pagination.page > 1
                    ? () {
                        // Handle previous page
                      }
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              ...List.generate(
                (tableData.pagination.totalPages).clamp(0, 5),
                (index) {
                  final pageNumber = index + 1;
                  final isCurrentPage = pageNumber == tableData.pagination.page;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: TextButton(
                      onPressed: isCurrentPage
                          ? null
                          : () {
                              // Handle page selection
                            },
                      style: TextButton.styleFrom(
                        backgroundColor: isCurrentPage
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        foregroundColor: isCurrentPage
                            ? Theme.of(context).colorScheme.onPrimary
                            : null,
                      ),
                      child: Text(pageNumber.toString()),
                    ),
                  );
                },
              ),
              IconButton(
                onPressed:
                    tableData.pagination.page < tableData.pagination.totalPages
                        ? () {
                            // Handle next page
                          }
                        : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
