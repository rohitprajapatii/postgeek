import 'package:equatable/equatable.dart';

class ConnectionInfo extends Equatable {
  final String host;
  final int port;
  final String database;
  final String username;
  final String? connectionString;

  const ConnectionInfo({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    this.connectionString,
  });

  @override
  List<Object?> get props => [host, port, database, username, connectionString];
}