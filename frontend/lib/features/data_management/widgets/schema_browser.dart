import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/data_management_bloc.dart';
import '../models/schema_info.dart';

class SchemaBrowser extends StatefulWidget {
  const SchemaBrowser({super.key});

  @override
  State<SchemaBrowser> createState() => _SchemaBrowserState();
}

class _SchemaBrowserState extends State<SchemaBrowser> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search tables...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchTerm.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchTerm = '';
                        });
                        context
                            .read<DataManagementBloc>()
                            .add(const SearchTables(''));
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {
                _searchTerm = value;
              });
              context.read<DataManagementBloc>().add(SearchTables(value));
            },
          ),
        ),

        // Content
        Expanded(
          child: BlocBuilder<DataManagementBloc, DataManagementState>(
            builder: (context, state) {
              if (state.status == DataManagementStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_searchTerm.isNotEmpty) {
                return _buildSearchResults(context, state);
              } else {
                return _buildSchemaList(context, state);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(BuildContext context, DataManagementState state) {
    if (state.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No tables found for "$_searchTerm"',
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

    return ListView.builder(
      itemCount: state.searchResults.length,
      itemBuilder: (context, index) {
        final table = state.searchResults[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.table_view),
            title: Text(table.tableName),
            subtitle: Text('${table.rowCount} rows'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Load table details and switch to table viewer
              context.read<DataManagementBloc>().add(
                    LoadTableDetails(
                      schemaName: 'public', // You might need to adjust this
                      tableName: table.tableName,
                    ),
                  );
              // Switch to table viewer tab
              DefaultTabController.of(context)?.animateTo(1);
            },
          ),
        );
      },
    );
  }

  Widget _buildSchemaList(BuildContext context, DataManagementState state) {
    if (state.schemas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_off,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No schemas found',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                context.read<DataManagementBloc>().add(const LoadSchemas());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: state.schemas.length,
      itemBuilder: (context, index) {
        final schema = state.schemas[index];
        return _SchemaExpansionTile(schema: schema);
      },
    );
  }
}

class _SchemaExpansionTile extends StatelessWidget {
  final SchemaInfo schema;

  const _SchemaExpansionTile({required this.schema});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: const Icon(Icons.folder),
        title: Text(schema.schemaName),
        subtitle: Text('${schema.tables.length} tables'),
        children: schema.tables.map((table) {
          return ListTile(
            leading: const Icon(Icons.table_view, size: 20),
            title: Text(table.tableName),
            subtitle: Text('${table.rowCount} rows'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Load table details and switch to table viewer
              context.read<DataManagementBloc>().add(
                    LoadTableDetails(
                      schemaName: schema.schemaName,
                      tableName: table.tableName,
                    ),
                  );
              // Switch to table viewer tab
              DefaultTabController.of(context)?.animateTo(1);
            },
          );
        }).toList(),
      ),
    );
  }
}
