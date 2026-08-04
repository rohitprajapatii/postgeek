import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/services/api_service.dart';
import '../../connection/bloc/connection_bloc.dart';
import '../models/query_data.dart';

part 'queries_event.dart';
part 'queries_state.dart';

class QueriesBloc extends Bloc<QueriesEvent, QueriesState> {
  final ApiService apiService;
  final ConnectionBloc connectionBloc;
  Timer? _refreshTimer;

  QueriesBloc({
    required this.apiService,
    required this.connectionBloc,
  }) : super(const QueriesState.initial()) {
    on<LoadQueries>(_onLoadQueries);
    on<StartQueriesRefresh>(_onStartQueriesRefresh);
    on<StopQueriesRefresh>(_onStopQueriesRefresh);
    on<ResetQueryStats>(_onResetQueryStats);
    on<EnableExtension>(_onEnableExtension);

    // Subscribe to connection state changes
    connectionBloc.stream.listen((connectionState) {
      if (connectionState.status == ConnectionStatus.connected) {
        add(StartQueriesRefresh());
      } else if (connectionState.status == ConnectionStatus.disconnected) {
        add(StopQueriesRefresh());
      }
    });
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }

  Future<void> _onLoadQueries(
    LoadQueries event,
    Emitter<QueriesState> emit,
  ) async {
    // Keep the old data while loading new data
    emit(state.copyWith(status: QueriesStatus.loading));

    try {
      // Fetch all required query data
      final slowQueriesResult = await _fetchSlowQueries(event.limit);
      final queryStats = await _fetchQueryStats();
      final queryTypes = await _fetchQueryTypes();

      List<dynamic> slowQueries;
      if (slowQueriesResult is List) {
        slowQueries = slowQueriesResult;
      } else if (slowQueriesResult is Map<String, dynamic> &&
          slowQueriesResult.containsKey('error')) {
        // This is the "extension not enabled" case. Wrap the error map in a list
        // so the UI can process it correctly.
        slowQueries = [slowQueriesResult];
      } else {
        // Handle any other unexpected format gracefully.
        slowQueries = [];
      }

      // Create query data object
      final queryData = QueryData(
        slowQueries: slowQueries,
        queryStats: queryStats,
        queryTypes: queryTypes,
        lastUpdated: DateTime.now(),
      );

      emit(state.copyWith(
        status: QueriesStatus.loaded,
        queryData: queryData,
        clearErrorMessage: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: QueriesStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onStartQueriesRefresh(
    StartQueriesRefresh event,
    Emitter<QueriesState> emit,
  ) {
    // Cancel any existing timer
    _refreshTimer?.cancel();

    // Load data immediately
    add(const LoadQueries());

    // Set up a periodic timer to refresh data
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      add(const LoadQueries());
    });
  }

  void _onStopQueriesRefresh(
    StopQueriesRefresh event,
    Emitter<QueriesState> emit,
  ) {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _onResetQueryStats(
    ResetQueryStats event,
    Emitter<QueriesState> emit,
  ) async {
    try {
      await apiService.post('/api/queries/reset');
      add(const LoadQueries());
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to reset query statistics: ${e.toString()}',
      ));
    }
  }

  Future<void> _onEnableExtension(
    EnableExtension event,
    Emitter<QueriesState> emit,
  ) async {
    emit(state.copyWith(status: QueriesStatus.enablingExtension));
    try {
      final response = await apiService.post('/api/queries/enable-extension');
      if (response.data['success'] == true) {
        // Show a temporary success message before reloading
        emit(state.copyWith(status: QueriesStatus.loaded));
        // Reload the data to reflect the change
        add(const LoadQueries());
      } else {
        emit(state.copyWith(
          status: QueriesStatus.error,
          errorMessage: response.data['error'] ?? 'Failed to enable extension',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: QueriesStatus.error,
        errorMessage: 'An error occurred: ${e.toString()}',
      ));
    }
  }

  Future<dynamic> _fetchSlowQueries(int limit) async {
    final response = await apiService
        .get('/api/queries/slow', queryParameters: {'limit': limit});
    return response.data;
  }

  Future<Map<String, dynamic>> _fetchQueryStats() async {
    final response = await apiService.get('/api/queries/stats');
    return response.data;
  }

  Future<List<dynamic>> _fetchQueryTypes() async {
    final response = await apiService.get('/api/queries/types');
    return response.data is List ? response.data : [];
  }
}
