part of 'queries_bloc.dart';

enum QueriesStatus {
  initial,
  loading,
  loaded,
  error,
  enablingExtension,
}

class QueriesState extends Equatable {
  final QueriesStatus status;
  final QueryData? queryData;
  final String? errorMessage;

  const QueriesState({
    required this.status,
    this.queryData,
    this.errorMessage,
  });

  const QueriesState.initial()
      : status = QueriesStatus.initial,
        queryData = null,
        errorMessage = null;

  QueriesState copyWith({
    QueriesStatus? status,
    QueryData? queryData,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return QueriesState(
      status: status ?? this.status,
      queryData: queryData ?? this.queryData,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, queryData, errorMessage];
}