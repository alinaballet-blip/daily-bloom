
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NutritionStorage {
  static const String _storageKey = 'daily_bloom_records_v1';

  static Future<Map<String, dynamic>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);

    if (saved == null) {
      return {};
    }

    try {
      final decoded = jsonDecode(saved);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // 遇到無效資料時，暫時回傳空資料。
    }

    return {};
  }

  static Future<void> save(
    Map<String, dynamic> records,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _storageKey,
      jsonEncode(records),
    );
  }
}
