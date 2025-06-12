part of 'dashboard_bloc.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object> get props => [];
}

class LoadDashboardData extends DashboardEvent {}

class StartDashboardRefresh extends DashboardEvent {}

class StopDashboardRefresh extends DashboardEvent {}