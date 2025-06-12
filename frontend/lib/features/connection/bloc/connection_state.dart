part of 'connection_bloc.dart';

enum ConnectionStatus {
  initial,
  connecting,
  connected,
  disconnected,
  error,
}

class ConnectionState extends Equatable {
  final ConnectionStatus status;
  final ConnectionInfo? connectionInfo;
  final String? errorMessage;

  const ConnectionState({
    required this.status,
    this.connectionInfo,
    this.errorMessage,
  });

  const ConnectionState.initial()
      : status = ConnectionStatus.initial,
        connectionInfo = null,
        errorMessage = null;

  ConnectionState copyWith({
    ConnectionStatus? status,
    ConnectionInfo? connectionInfo,
    String? errorMessage,
  }) {
    return ConnectionState(
      status: status ?? this.status,
      connectionInfo: connectionInfo ?? this.connectionInfo,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, connectionInfo, errorMessage];
}