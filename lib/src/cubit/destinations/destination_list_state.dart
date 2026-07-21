part of 'destination_list_cubit.dart';

abstract class DestinationListState {}

class DestinationListLoadingState extends DestinationListState {}

class DestinationListErrorState extends DestinationListState {}

class DestinationListSuccessState extends DestinationListState {
  final List<DestinationListItem> items;
  final bool hasMore;
  final bool loadingMore;

  DestinationListSuccessState(
    this.items, {
    required this.hasMore,
    required this.loadingMore,
  });
}
