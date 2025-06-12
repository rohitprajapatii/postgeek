part of 'activity_bloc.dart';

abstract class ActivityEvent extends Equatable {
  const ActivityEvent();

  @override
  List<Object> get props => [];
}

class LoadActivity extends ActivityEvent {}

class StartActivityRefresh extends ActivityEvent {}

class StopActivityRefresh extends ActivityEvent {}

class TerminateSession extends ActivityEvent {
  final int pid;

  const TerminateSession(this.pid);

  @override
  List<Object> get props => [pid];
}