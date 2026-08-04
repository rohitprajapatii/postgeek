part of 'queries_bloc.dart';

abstract class QueriesEvent extends Equatable {
  const QueriesEvent();

  @override
  List<Object> get props => [];
}

class LoadQueries extends QueriesEvent {
  final int limit;

  const LoadQueries({this.limit = 20});

  @override
  List<Object> get props => [limit];
}

class StartQueriesRefresh extends QueriesEvent {}

class StopQueriesRefresh extends QueriesEvent {}

class ResetQueryStats extends QueriesEvent {}

class EnableExtension extends QueriesEvent {} 