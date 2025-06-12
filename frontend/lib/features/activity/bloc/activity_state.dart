part of 'activity_bloc.dart';

enum ActivityStatus {
  initial,
  loading,
  loaded,
  error,
}

class ActivityState extends Equatable {
  final ActivityStatus status;
  final ActivityData? activityData;
  final String? errorMessage;
  final String? terminationMessage;

  const ActivityState({
    required this.status,
    this.activityData,
    this.errorMessage,
    this.terminationMessage,
  });

  const ActivityState.initial()
      : status = ActivityStatus.initial,
        activityData = null,
        errorMessage = null,
        terminationMessage = null;

  ActivityState copyWith({
    ActivityStatus? status,
    ActivityData? activityData,
    String? errorMessage,
    String? terminationMessage,
  }) {
    return ActivityState(
      status: status ?? this.status,
      activityData: activityData ?? this.activityData,
      errorMessage: errorMessage,
      terminationMessage: terminationMessage,
    );
  }

  @override
  List<Object?> get props => [status, activityData, errorMessage, terminationMessage];
}