import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/service/news/news_read_store.dart';

/// Bell ikonkasi ustiga o'qilmagan yangiliklar sonini (badge) chizadi.
///
/// O'zi mustaqil: ochilganda Firestore'dan sonini yuklaydi va global
/// [NewsReadStore.unreadCount] o'zgarganda avtomatik yangilanadi (yangilik
/// o'qilgach badge kamayadi).
class NewsUnreadBadge extends StatefulWidget {
  const NewsUnreadBadge({super.key, required this.child});

  final Widget child;

  @override
  State<NewsUnreadBadge> createState() => _NewsUnreadBadgeState();
}

class _NewsUnreadBadgeState extends State<NewsUnreadBadge> {
  @override
  void initState() {
    super.initState();
    NewsReadStore().refreshUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NewsReadStore().unreadCount,
      builder: (context, count, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child!,
            if (count > 0)
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xffE53935),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      child: widget.child,
    );
  }
}
