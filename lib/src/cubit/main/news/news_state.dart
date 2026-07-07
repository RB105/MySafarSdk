part of 'news_cubit.dart';

abstract class NewsState extends Equatable {
  const NewsState();

  @override
  List<Object?> get props => [];
}

class NewsInitState extends NewsState {
  const NewsInitState();
}

class NewsLoadingState extends NewsState {
  const NewsLoadingState();
}

class NewsSuccessState extends NewsState {
  final List<NewsModel> news;
  final Set<String> readIds;
  const NewsSuccessState(this.news, this.readIds);

  int get unreadCount =>
      news.where((n) => !readIds.contains(n.id)).length;

  bool isRead(String id) => readIds.contains(id);

  @override
  List<Object?> get props => [news, readIds];
}

class NewsErrorState extends NewsState {
  const NewsErrorState();
}
