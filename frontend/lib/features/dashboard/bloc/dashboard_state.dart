part of 'dashboard_bloc.dart';

enum DashboardStatus {
  initial,
  loading,
  loaded,
  error,
}

class DashboardState extends Equatable {
  final DashboardStatus status;
  final DashboardData? dashboardData;
  final String? errorMessage;

  const DashboardState({
    required this.status,
    this.dashboardData,
    this.errorMessage,
  });

  const DashboardState.initial()
      : status = DashboardStatus.initial,
        dashboardData = null,
        errorMessage = null;

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardData? dashboardData,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      dashboardData: dashboardData ?? this.dashboardData,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, dashboardData, errorMessage];
}