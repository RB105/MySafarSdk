import 'package:cached_network_image/cached_network_image.dart';
import 'package:mysafar_sdk/src/cubit/main/news/news_cubit.dart';
import 'package:mysafar_sdk/src/generated/assets.dart' show Assets;
import 'package:mysafar_sdk/src/model/remote/news/news_model.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/view/main/pages/news_detail_page.dart';

/// "News" tab'ining ichki qismi — Firestore'dagi yangiliklar ro'yxati.
///
/// [NewsCubit] ni ajdod (ancestor) widget beradi (NotificationPage), shuning
/// uchun debug paneli ham xuddi shu cubit'ni yangilay oladi.
class NewsListView extends StatelessWidget {
  const NewsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewsCubit, NewsState>(
      builder: (context, state) {
        if (state is NewsLoadingState || state is NewsInitState) {
          return const Padding(
            padding: EdgeInsets.only(top: 48),
            child: LoadingWidget(),
          );
        }

        if (state is NewsErrorState) {
          return _MessageView(
            text: "news_error".tr(),
            actionLabel: "try_again".tr(),
            onAction: () => context.read<NewsCubit>().getNews(),
          );
        }

        if (state is NewsSuccessState) {
          if (state.news.isEmpty) return const _EmptyNews();

          return Column(
            children: [
              if (state.unreadCount > 0)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.read<NewsCubit>().markAllRead(),
                    child: Text("news_mark_all_read".tr()),
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => context.read<NewsCubit>().getNews(),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: state.news.length,
                    separatorBuilder: (_, __) => context.szBoxHeight12,
                    itemBuilder: (context, index) {
                      final item = state.news[index];
                      return _NewsCard(
                        news: item,
                        isRead: state.isRead(item.id),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.news, required this.isRead});

  final NewsModel news;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final date = news.createdAt;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        // Ochilishi bilan o'qilgan deb belgilanadi.
        context.read<NewsCubit>().markAsRead(news.id);
        Navigator.of(context).pushNamed(
          NewsDetailPage.routeName,
          arguments: news,
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.color.surface,
          borderRadius: BorderRadius.circular(12),
          border: context.boxBorder,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news.hasImage)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: news.imageUrl,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 160,
                    color: context.color.surfaceContainerHighest,
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 160,
                    color: context.color.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            Padding(
              padding: context.k12Padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isRead) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 6, right: 6),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xff0057BE),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                      Expanded(
                        child: Text(
                          news.titleFor(context.locale.languageCode),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.displayMedium?.copyWith(
                            fontSize: 15.0,
                            fontWeight:
                                isRead ? FontWeight.w500 : FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (news.contentFor(context.locale.languageCode).isNotEmpty) ...[
                    context.szBoxHeight4,
                    Text(
                      news.contentFor(context.locale.languageCode),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleMedium
                          ?.copyWith(fontSize: 13.0),
                    ),
                  ],
                  if (date != null) ...[
                    context.szBoxHeight8,
                    Text(
                      DateFormat('dd.MM.yyyy, HH:mm').format(date),
                      style: context.textTheme.titleMedium
                          ?.copyWith(fontSize: 12.0),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyNews extends StatelessWidget {
  const _EmptyNews();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        context.szBoxHeight16,
        Center(
          child: SizedBox(
            width: 48,
            height: 48,
            child: Image.asset(Assets.homeNotificationEmpty),
          ),
        ),
        Text(
          "news_empty_header".tr(),
          style: context.textTheme.displayMedium?.copyWith(fontSize: 14.0),
        ),
        Text(
          "news_empty_sub".tr(),
          style: context.textTheme.titleMedium?.copyWith(fontSize: 14.0),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Text(
            text,
            style: context.textTheme.titleMedium?.copyWith(fontSize: 14.0),
            textAlign: TextAlign.center,
          ),
          context.szBoxHeight12,
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
