import 'package:dio/dio.dart';
import 'package:flutter/material.dart' show debugPrint;

class GeolocatorService {
  Future<String> getCurrentCity() async {
    final dio = Dio(BaseOptions(
        validateStatus: (int? statusCode) {
          if (statusCode != null) {
            if (statusCode >= 100 && statusCode <= 599) {
              return true;
            } else {
              return false;
            }
          } else {
            return false;
          }
        },
        receiveDataWhenStatusError: true));

    try {
      final response = await dio.get('https://ipapi.co/json');
      
      if (response.statusCode == 200) {
        debugPrint("${response.data['region']}");
        return "${response.data['region']}";
      }

      return '';
    } catch (e) {
      // Xatolikni jim yutib yubormaslik uchun log qilamiz; chaqiruvchi
      // bo'sh string kontraktiga tayanadi, shuning uchun '' qaytaramiz.
      debugPrint('GeolocatorService.getCurrentCity error: $e');
      return '';
    }
  }
}
