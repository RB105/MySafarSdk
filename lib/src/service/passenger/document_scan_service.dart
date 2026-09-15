import 'package:dio/dio.dart' show FormData, MultipartFile;
import 'package:mysafar_sdk/src/core/config/request_config.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/core/constants/end_points.dart';
import 'package:mysafar_sdk/src/model/remote/profile/users_model.dart';

/// `/v1/document/scan` natijasi.
class DocumentScanResult {
  const DocumentScanResult({
    required this.passenger,
    this.missingFields = const [],
  });

  /// Tanilgan maydonlar (sanalar `dd.MM.yyyy`, tanilmaganlari bo'sh).
  final UsersModel passenger;

  /// Server `warnings[].code == missing_fields` bilan qaytargan maydonlar.
  final List<String> missingFields;

  /// Hujjatdan hech qanday asosiy ma'lumot o'qilmagan (hujjat emas, xira
  /// yoki to'liq tushmagan rasm).
  bool get isEmpty =>
      (passenger.lastname ?? '').isEmpty &&
      (passenger.firstname ?? '').isEmpty &&
      (passenger.docnum ?? '').isEmpty;

  factory DocumentScanResult.fromJson(Map<String, dynamic> json) {
    final passenger = json['passenger'];
    final missing = <String>[];
    final warnings = json['warnings'];
    if (warnings is List) {
      for (final w in warnings) {
        if (w is Map && w['code'] == 'missing_fields' && w['fields'] is List) {
          missing.addAll((w['fields'] as List).map((f) => f.toString()));
        }
      }
    }
    return DocumentScanResult(
      passenger: UsersModel.fromDocumentScan(
        passenger is Map ? Map<String, dynamic>.from(passenger) : const {},
      ),
      missingFields: missing,
    );
  }
}

/// Pasport/ID karta rasmini serverga yuborib, yo'lovchi ma'lumotlarini
/// o'qiydi. Auth talab qilinmaydi.
class DocumentScanService with RequestConfig {
  /// [imagePath] — kamera yoki galereyadan olingan rasm fayli.
  /// Muvaffaqiyatda `NetworkSuccessResponse(data: DocumentScanResult)`.
  Future<NetworkResponse> scan(String imagePath) async {
    final fileName = imagePath.split(RegExp(r'[\\/]')).last;
    final MultipartFile image;
    try {
      image = await MultipartFile.fromFile(imagePath, filename: fileName);
    } catch (_) {
      // Fayl o'qilmadi (o'chirilgan / ruxsat yo'q) — UI yuklash holatida
      // qotib qolmasin.
      return const NetworkErrorResponse(
        error: '',
        errorType: ErrorType.other,
      );
    }
    final response = await postMultipartRequest(
      endPoint: EndPoints.document_scan,
      data: FormData.fromMap({'image': image}),
    );
    if (response is! NetworkSuccessResponse) return response;

    final body = response.data;
    if (body is! Map) {
      return const NetworkErrorResponse(
        error: '',
        errorType: ErrorType.other,
      );
    }
    return NetworkSuccessResponse(
      data: DocumentScanResult.fromJson(Map<String, dynamic>.from(body)),
    );
  }
}
