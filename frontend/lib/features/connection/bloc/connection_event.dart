part of 'connection_bloc.dart';

abstract class ConnectionEvent extends Equatable {
  const ConnectionEvent();

  @override
  List<Object?> get props => [];
}

class ConnectRequested extends ConnectionEvent {
  final String apiUrl;
  final String? connectionString;
  final String? host;
  final int? port;
  final String? database;
  final String? username;
  final String? password;

  const ConnectRequested({
    required this.apiUrl,
    this.connectionString,
    this.host,
    this.port,
    this.database,
    this.username,
    this.password,
  });

  @override
  List<Object?> get props => [
        apiUrl,
        connectionString,
        host,
        port,
        database,
        username,
        password,
      ];
}

class DisconnectRequested extends ConnectionEvent {}

class ResetConnection extends ConnectionEvent {}
