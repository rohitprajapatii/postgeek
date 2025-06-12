import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/services/api_service.dart';
import '../../connection/bloc/connection_bloc.dart';
import '../models/dashboard_data.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final ApiService apiService;
  final ConnectionBloc connectionBloc;
  Timer? _refreshTimer;

  DashboardBloc({
    required this.apiService,
    required this.connectionBloc,
  }) : super(const DashboardState.initial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
    on<StartDashboardRefresh>(_onStartDashboardRefresh);
    on<StopDashboardRefresh>(_onStopDashboardRefresh);

    // Subscribe to connection state changes
    connectionBloc.stream.listen((connectionState) {
      if (connectionState.status == ConnectionStatus.connected) {
        add(StartDashboardRefresh());
      } else if (connectionState.status == ConnectionStatus.disconnected) {
        add(StopDashboardRefresh());
      }
    });
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(status: DashboardStatus.loading));

    try {
      // Fetch all required dashboard data
      final databaseOverview = await _fetchDatabaseOverview();
      final slowQueries = await _fetchSlowQueries();
      final activeSessions = await _fetchActiveSessions();
      final healthOverview = await _fetchHealthOverview();
      final tableStats = await _fetchTableStats();
      final queryStats = await _fetchQueryStats();

      // Create dashboard data object
      final dashboardData = DashboardData(
        databaseOverview: databaseOverview,
        slowQueries: slowQueries,
        activeSessions: activeSessions,
        healthOverview: healthOverview,
        tableStats: tableStats,
        queryStats: queryStats,
        lastUpdated: DateTime.now(),
      );

      emit(state.copyWith(
        status: DashboardStatus.loaded,
        dashboardData: dashboardData,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onStartDashboardRefresh(
    StartDashboardRefresh event,
    Emitter<DashboardState> emit,
  ) {
    // Cancel any existing timer
    _refreshTimer?.cancel();

    // Load data immediately
    add(LoadDashboardData());

    // Set up a periodic timer to refresh data
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      add(LoadDashboardData());
    });
  }

  void _onStopDashboardRefresh(
    StopDashboardRefresh event,
    Emitter<DashboardState> emit,
  ) {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<Map<String, dynamic>> _fetchDatabaseOverview() async {
    final response = await apiService.get('/api/statistics/overview');
    return response.data;
  }

  Future<List<dynamic>> _fetchSlowQueries() async {
    final response = await apiService.get('/api/queries/slow', queryParameters: {'limit': 5});
    return response.data is List ? response.data : [];
  }

  Future<List<dynamic>> _fetchActiveSessions() async {
    final response = await apiService.get('/api/activity/sessions/active');
    return response.data is List ? response.data : [];
  }

  Future<Map<String, dynamic>> _fetchHealthOverview() async {
    final response = await apiService.get('/api/health');
    return response.data;
  }

  Future<List<dynamic>> _fetchTableStats() async {
    final response = await apiService.get('/api/statistics/tables');
    return response.data is List ? response.data : [];
  }

  Future<Map<String, dynamic>> _fetchQueryStats() async {
    final response = await apiService.get('/api/queries/stats');
    return response.data;
  }
}