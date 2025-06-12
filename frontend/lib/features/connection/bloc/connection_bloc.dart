import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/services/api_service.dart';
import '../models/connection_info.dart';

part 'connection_event.dart';
part 'connection_state.dart';

class ConnectionBloc extends Bloc<ConnectionEvent, ConnectionState> {
  final ApiService apiService;

  ConnectionBloc({required this.apiService})
      : super(const ConnectionState.initial()) {
    on<ConnectRequested>(_onConnectRequested);
    on<DisconnectRequested>(_onDisconnectRequested);
  }

  Future<void> _onConnectRequested(
    ConnectRequested event,
    Emitter<ConnectionState> emit,
  ) async {
    emit(state.copyWith(status: ConnectionStatus.connecting));

    try {
      // Set the API service base URL
      apiService.setBaseUrl(event.apiUrl);

      // Try to connect to the database
      final response = await apiService.post(
        '/api/database/connect',
        data: {
          if (event.connectionString != null)
            'connectionString': event.connectionString
          else ...<String, dynamic>{
            'host': event.host,
            'port': event.port,
            'database': event.database,
            'username': event.username,
            'password': event.password,
          },
        },
      );

      if (response.statusCode == 200) {
        // Create connection info object
        final connectionInfo = ConnectionInfo(
          host: event.host ?? 'Unknown host',
          port: event.port ?? 5432,
          database: event.database ?? 'Unknown database',
          username: event.username ?? 'Unknown user',
          connectionString: event.connectionString,
        );

        emit(state.copyWith(
          status: ConnectionStatus.connected,
          connectionInfo: connectionInfo,
          errorMessage: null,
        ));
      } else {
        emit(state.copyWith(
          status: ConnectionStatus.error,
          errorMessage: 'Failed to connect to database',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDisconnectRequested(
    DisconnectRequested event,
    Emitter<ConnectionState> emit,
  ) async {
    try {
      // Disconnect from the database
      await apiService.delete('/api/database/disconnect');
    } catch (e) {
      // Ignore any errors on disconnect
    } finally {
      // Always reset the connection state
      emit(const ConnectionState.initial());
    }
  }
}
