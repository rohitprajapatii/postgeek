import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../bloc/connection_bloc.dart';

class ConnectionForm extends StatefulWidget {
  final bool isConnecting;

  const ConnectionForm({
    super.key,
    required this.isConnecting,
  });

  @override
  State<ConnectionForm> createState() => _ConnectionFormState();
}

class _ConnectionFormState extends State<ConnectionForm> {
  final _formKey = GlobalKey<FormState>();
  
  final _apiUrlController = TextEditingController(text: 'http://localhost:3000');
  final _hostController = TextEditingController(text: 'localhost');
  final _portController = TextEditingController(text: '5432');
  final _databaseController = TextEditingController();
  final _usernameController = TextEditingController(text: 'postgres');
  final _passwordController = TextEditingController();
  final _connectionStringController = TextEditingController();
  
  bool _useConnectionString = false;

  @override
  void dispose() {
    _apiUrlController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _databaseController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _connectionStringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // API URL Field
          TextFormField(
            controller: _apiUrlController,
            decoration: const InputDecoration(
              labelText: 'API URL',
              hintText: 'http://localhost:3000',
              prefixIcon: Icon(Icons.api),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the API URL';
              }
              try {
                Uri.parse(value);
              } catch (e) {
                return 'Please enter a valid URL';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          // Connection Method Toggle
          Row(
            children: [
              const Text('Connection Method:'),
              const SizedBox(width: 16),
              ChoiceChip(
                label: const Text('Connection Details'),
                selected: !_useConnectionString,
                onSelected: (selected) {
                  setState(() {
                    _useConnectionString = !selected;
                  });
                },
                backgroundColor: AppColors.chipBackground,
                selectedColor: AppColors.primary.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: !_useConnectionString 
                      ? AppColors.primary 
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Connection String'),
                selected: _useConnectionString,
                onSelected: (selected) {
                  setState(() {
                    _useConnectionString = selected;
                  });
                },
                backgroundColor: AppColors.chipBackground,
                selectedColor: AppColors.primary.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: _useConnectionString 
                      ? AppColors.primary 
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Connection Fields
          if (_useConnectionString)
            TextFormField(
              controller: _connectionStringController,
              decoration: const InputDecoration(
                labelText: 'Connection String',
                hintText: 'postgresql://username:password@localhost:5432/database',
                prefixIcon: Icon(Icons.code),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a connection string';
                }
                if (!value.startsWith('postgresql://')) {
                  return 'Connection string should start with postgresql://';
                }
                return null;
              },
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _hostController,
                        decoration: const InputDecoration(
                          labelText: 'Host',
                          hintText: 'localhost',
                          prefixIcon: Icon(Icons.dns),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _portController,
                        decoration: const InputDecoration(
                          labelText: 'Port',
                          hintText: '5432',
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          final port = int.tryParse(value);
                          if (port == null || port <= 0 || port > 65535) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _databaseController,
                  decoration: const InputDecoration(
                    labelText: 'Database',
                    hintText: 'postgres',
                    prefixIcon: Icon(Icons.storage),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a database name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'postgres',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
              ],
            ),
          
          const SizedBox(height: 32),
          
          // Connect Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: widget.isConnecting 
                  ? null 
                  : () {
                      if (_formKey.currentState!.validate()) {
                        _connect();
                      }
                    },
              child: widget.isConnecting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Connect'),
            ),
          ),
        ],
      ),
    );
  }

  void _connect() {
    final apiUrl = _apiUrlController.text.trim();
    
    if (_useConnectionString) {
      context.read<ConnectionBloc>().add(
            ConnectRequested(
              apiUrl: apiUrl,
              connectionString: _connectionStringController.text.trim(),
            ),
          );
    } else {
      final port = int.tryParse(_portController.text.trim());
      
      context.read<ConnectionBloc>().add(
            ConnectRequested(
              apiUrl: apiUrl,
              host: _hostController.text.trim(),
              port: port,
              database: _databaseController.text.trim(),
              username: _usernameController.text.trim(),
              password: _passwordController.text.trim(),
            ),
          );
    }
  }
}