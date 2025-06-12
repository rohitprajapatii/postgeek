import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/services/api_service.dart';
import '../../connection/bloc/connection_bloc.dart';
import '../models/activity_data.dart';

part 'activity_event.dart';
part 'activity_state.dart';

class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final ApiService apiService;
  final ConnectionBloc connectionBloc;
  Timer? _refreshTimer;

  ActivityBloc({
    required this.apiService,
    required this.connectionBloc,
  }) : super(const ActivityState.initial()) {
    on<LoadActivity>(_onLoadActivity);
    on<StartActivityRefresh>(_onStartActivityRefresh);
    on<StopActivityRefresh>(_onStopActivityRefresh);
    on<TerminateSession>(_onTerminateSession);

    // Subscribe to connection state changes
    connectionBloc.stream.listen((connectionState) {
      if (connectionState.status == ConnectionStatus.connected) {
        add(StartActivityRefresh());
      } else if (connectionState.status == ConnectionStatus.disconnected) {
        add(StopActivityRefresh());
      }
    });
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }

  Future<void> _onLoadActivity(
    LoadActivity event,
    Emitter<ActivityState> emit,
  ) async {
    emit(state.copyWith(status: ActivityStatus.loading));

    try {
      // Fetch all required activity data
      final activeSessions = await _fetchActiveSessions();
      final idleSessions = await _fetchIdleSessions();
      final locks = await _fetchLocks();
      final blockedQueries = await _fetchBlockedQueries();

      // Create activity data object
      final activityData = ActivityData(
        activeSessions: activeSessions,
        idleSessions: idleSessions,
        locks: locks,
        blockedQueries: blockedQueries,
        lastUpdated: DateTime.now(),
      );

      emit(state.copyWith(
        status: ActivityStatus.loaded,
        activityData: activityData,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ActivityStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onStartActivityRefresh(
    StartActivityRefresh event,
    Emitter<ActivityState> emit,
  ) {
    // Cancel any existing timer
    _refreshTimer?.cancel();

    // Load data immediately
    add(LoadActivity());

    // Set up a periodic timer to refresh data
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      add(LoadActivity());
    });
  }

  void _onStopActivityRefresh(
    StopActivityRefresh event,
    Emitter<ActivityState> emit,
  ) {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _onTerminateSession(
    TerminateSession event,
    Emitter<ActivityState> emit,
  ) async {
    try {
      await apiService.delete('/api/activity/sessions/${event.pid}');
      
      // Reload data after termination
      add(LoadActivity());
      
      emit(state.copyWith(
        terminationMessage: 'Session ${event.pid} terminated successfully',
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to terminate session: ${e.toString()}',
      ));
    }
  }

  Future<List<dynamic>> _fetchActiveSessions() async {
    final response = await apiService.get('/api/activity/sessions/active');
    return response.data is List ? response.data : [];
  }

  Future<List<dynamic>> _fetchIdleSessions() async {
    final response = await apiService.get('/api/activity/sessions/idle');
    return response.data is List ? response.data : [];
  }

  Future<List<dynamic>> _fetchLocks() async {
    final response = await apiService.get('/api/activity/locks');
    return response.data is List ? response.data : [];
  }

  Future<List<dynamic>> _fetchBlockedQueries() async {
    final response = await apiService.get('/api/activity/blocked');
    return response.data is List ? response.data : [];
  }
}