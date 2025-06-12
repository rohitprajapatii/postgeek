part of 'health_bloc.dart';

abstract class HealthEvent extends Equatable {
  const HealthEvent();

  @override
  List<Object> get props => [];
}

class LoadHealthData extends HealthEvent {}

class StartHealthRefresh extends HealthEvent {}

class StopHealthRefresh extends HealthEvent {}