part of 'health_bloc.dart';

enum HealthStatus {
  initial,
  loading,
  loaded,
  error,
}

class HealthState extends Equatable {
  final HealthStatus status;
  final HealthData? healthData;
  final String? errorMessage;

  const HealthState({
    required this.status,
    this.healthData,
    this.errorMessage,
  });

  const HealthState.initial()
      : status = HealthStatus.initial,
        healthData = null,
        errorMessage = null;

  HealthState copyWith({
    HealthStatus? status,
    HealthData? healthData,
    String? errorMessage,
  }) {
    return HealthState(
      status: status ?? this.status,
      healthData: healthData ?? this.healthData,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, healthData, errorMessage];
}