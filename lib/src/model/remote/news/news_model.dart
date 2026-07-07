import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore `news` collection'idagi bitta yangilik.
///
/// `title` va `content` KO'P TILLI (Map `{uz, ru, en}`) saqlanadi. Eski
/// hujjatlarда oddiy string bo'lishi mumkin — u standart tilga (uz) joylanadi.
/// `route` — bosilganda ilova ichida navigatsiya uchun (ixtiyoriy).
/// ```
/// news/<docId>
///   title:     { uz, ru, en }  yoki string (eski)
///   content:   { uz, ru, en }  yoki string (eski)
///   imageUrl:  string
///   route:     string          (ixtiyoriy)
///   createdAt: timestamp
///   isActive:  bool
/// ```
class NewsModel {
  final String id;
  final Map<String, String> title;
  final Map<String, String> content;
  final String imageUrl;
  final String route;
  final DateTime? createdAt;

  const NewsModel({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.route,
    required this.createdAt,
  });

  factory NewsModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return NewsModel(
      id: doc.id,
      title: _localized(data['title']),
      content: _localized(data['content']),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      route: (data['route'] ?? '').toString(),
      createdAt: _parseDate(data['createdAt']),
    );
  }

  bool get hasImage => imageUrl.trim().isNotEmpty;

  /// Joriy [lang] tiliga mos sarlavha; mos til bo'lmasa (masalan tojik, qozoq,
  /// turk) DEFAULT — rus tili (ru→uz→en zaxirasi).
  String titleFor(String lang) => _resolve(title, lang);

  /// Joriy [lang] tiliga mos matn; mos til bo'lmasa default — rus tili.
  String contentFor(String lang) => _resolve(content, lang);

  /// Hive keshi uchun primitive Map (createdAt millisekundda saqlanadi).
  Map<String, dynamic> toCacheMap() => {
        'id': id,
        'title': title,
        'content': content,
        'imageUrl': imageUrl,
        'route': route,
        'createdAt': createdAt?.millisecondsSinceEpoch,
      };

  /// Hive keshidan o'qish.
  factory NewsModel.fromCacheMap(Map<String, dynamic> map) {
    final ts = map['createdAt'];
    return NewsModel(
      id: (map['id'] ?? '').toString(),
      title: _localized(map['title']),
      content: _localized(map['content']),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      route: (map['route'] ?? '').toString(),
      createdAt: ts is int ? DateTime.fromMillisecondsSinceEpoch(ts) : null,
    );
  }

  /// Map (ko'p tilli) yoki string (eski) qiymatni `{lang: text}` ga aylantiradi.
  static Map<String, String> _localized(dynamic raw) {
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), (v ?? '').toString()));
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return {'uz': raw};
    }
    return const {};
  }

  static String _resolve(Map<String, String> map, String lang) {
    final v = map[lang];
    if (v != null && v.trim().isNotEmpty) return v.trim();
    // Tanlangan til bo'lmasa — DEFAULT rus, keyin uz, keyin en.
    for (final f in const ['ru', 'uz', 'en']) {
      final fv = map[f];
      if (fv != null && fv.trim().isNotEmpty) return fv.trim();
    }
    for (final fv in map.values) {
      if (fv.trim().isNotEmpty) return fv.trim();
    }
    return '';
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }
}
