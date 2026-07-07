import 'package:cached_network_image/cached_network_image.dart';
import 'package:mysafar_sdk/src/model/remote/news/news_model.dart';
import 'package:mysafar_sdk/src/service/news/news_read_store.dart';
import 'package:mysafar_sdk/src/service/news/news_repository.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

class NewsDetailPage extends StatefulWidget {
  const NewsDetailPage({super.key, required this.news});

  final NewsModel news;

  static const routeName = '/news-detail';

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  @override
  void initState() {
    super.initState();
   final store = NewsReadStore();
    if (!store.isRead(widget.news.id)) {
      store.markRead(widget.news.id);
      final current = store.unreadCount.value;
      if (current > 0) store.unreadCount.value = current - 1;


      NewsRepository().incrementReadCount(widget.news.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final news = widget.news;
    final date = news.createdAt;
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          "notification_page_news".tr(),
          style: context.textTheme.bodyMedium,
        ),
        elevation: 4.0,
        shadowColor: Colors.black38,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news.hasImage)
              CachedNetworkImage(
                imageUrl: news.imageUrl,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 220,
                  color: context.color.surfaceContainerHighest,
                ),
                errorWidget: (context, url, error) => Container(
                  height: 220,
                  color: context.color.surfaceContainerHighest,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            Padding(
              padding: context.k16Padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (date != null) ...[
                    Text(
                      DateFormat('dd.MM.yyyy, HH:mm').format(date),
                      style: context.textTheme.titleMedium
                          ?.copyWith(fontSize: 13.0),
                    ),
                    context.szBoxHeight8,
                  ],
                  Text(
                    news.titleFor(context.locale.languageCode),
                    style: context.textTheme.displayMedium
                        ?.copyWith(fontSize: 20.0),
                  ),
                  context.szBoxHeight12,
                  Text(
                    news.contentFor(context.locale.languageCode),
                    style: context.textTheme.bodyMedium
                        ?.copyWith(fontSize: 15.0, height: 1.5),
                  ),
                  context.szBoxHeight24,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
