import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/services/api_service.dart';
import '../../connection/bloc/connection_bloc.dart';
import '../models/health_data.dart';

part 'health_event.dart';
part 'health_state.dart';

class HealthBloc extends Bloc<HealthEvent, HealthState> {
  final ApiService apiService;
  final ConnectionBloc connectionBloc;
  Timer? _refreshTimer;

  HealthBloc({
    required this.apiService,
    required this.connectionBloc,
  }) : super(const HealthState.initial()) {
    on<LoadHealthData>(_onLoadHealthData);
    on<StartHealthRefresh>(_onStartHealthRefresh);
    on<StopHealthRefresh>(_onStopHealthRefresh);

    // Subscribe to connection state changes
    connectionBloc.stream.listen((connectionState) {
      if (connectionState.status == ConnectionStatus.connected) {
        add(StartHealthRefresh());
      } else if (connectionState.status == ConnectionStatus.disconnected) {
        add(StopHealthRefresh());
      }
    });
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }

  Future<void> _onLoadHealthData(
    LoadHealthData event,
    Emitter<HealthState> emit,
  ) async {
    emit(state.copyWith(status: HealthStatus.loading));

    try {
      // Fetch all required health data
      final healthOverview = await _fetchHealthOverview();
      final missingIndexes = await _fetchMissingIndexes();
      final unusedIndexes = await _fetchUnusedIndexes();
      final tableBloat = await _fetchTableBloat();

      // Create health data object
      final healthData = HealthData(
        healthOverview: healthOverview,
        missingIndexes: missingIndexes,
        unusedIndexes: unusedIndexes,
        tableBloat: tableBloat,
        lastUpdated: DateTime.now(),
      );

      emit(state.copyWith(
        status: HealthStatus.loaded,
        healthData: healthData,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HealthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onStartHealthRefresh(
    StartHealthRefresh event,
    Emitter<HealthState> emit,
  ) {
    // Cancel any existing timer
    _refreshTimer?.cancel();

    // Load data immediately
    add(LoadHealthData());

    // Set up a periodic timer to refresh data
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      add(LoadHealthData());
    });
  }

  void _onStopHealthRefresh(
    StopHealthRefresh event,
    Emitter<HealthState> emit,
  ) {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<Map<String, dynamic>> _fetchHealthOverview() async {
    final response = await apiService.get('/api/health');
    return response.data;
  }

  Future<List<dynamic>> _fetchMissingIndexes() async {
    final response = await apiService.get('/api/health/missing-indexes');
    return response.data is List ? response.data : [];
  }

  Future<List<dynamic>> _fetchUnusedIndexes() async {
    final response = await apiService.get('/api/health/unused-indexes');
    return response.data is List ? response.data : [];
  }

  Future<List<dynamic>> _fetchTableBloat() async {
    final response = await apiService.get('/api/health/table-bloat');
    return response.data is List ? response.data : [];
  }
}