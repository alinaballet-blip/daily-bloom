
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:file_picker/file_picker.dart' as fp;
import '../services/nutrition_storage.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  Future<void> exportRecords(BuildContext context) async {
  try {
    // 讀取所有日期的飲食紀錄
    final records = await NutritionStorage.load();

    // 轉換成格式化的 JSON
    final jsonText =
        const JsonEncoder.withIndent('  ').convert(records);

    // 轉換成檔案資料
    final bytes = Uint8List.fromList(utf8.encode(jsonText));

    // 建立備份檔名
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // 下載 JSON 備份
    await FileSaver.instance.saveFile(
      name: 'daily_bloom_backup_$date',
      bytes: bytes,
      fileExtension: 'json',
      mimeType: MimeType.json,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('飲食紀錄已匯出 🌷')),
    );
  } catch (e) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('匯出失敗：$e')),
    );
  }
}
Future<void> importRecords(BuildContext context) async {
  try {
  final files = await fp.FilePicker.pickFiles(
  type: fp.FileType.custom,
  allowedExtensions: ['json'],
);

if (files.isEmpty) return;

final file = files.single;
final bytes = await file.readAsBytes();

    final jsonText = utf8.decode(bytes);
debugPrint('匯入檔案內容：$jsonText');

final decoded = jsonDecode(jsonText);
debugPrint('解析後的資料類型：${decoded.runtimeType}');

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('JSON 格式不正確');
    }

    
if (!context.mounted) return;

// 匯入前先詢問使用者
final confirmed = await showDialog<bool>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    title: const Text('確認合併飲食紀錄？'),
    content: const Text(
      '將保留目前其他日期的紀錄，並加入備份資料。\n\n'
      '如果日期相同，會以備份檔的紀錄為準。',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(dialogContext, false),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(dialogContext, true),
        child: const Text('確認匯入'),
      ),
    ],
  ),
);

if (confirmed != true) return;

// 讀取現有紀錄並合併備份
final existingRecords = await NutritionStorage.load();

final mergedRecords = <String, dynamic>{
  ...existingRecords,
  ...decoded,
};

// 儲存合併後的資料
await NutritionStorage.save(mergedRecords);

if (!context.mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('飲食紀錄合併還原成功 ♡'),
  ),
);

  } catch (e) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('讀取備份失敗：$e')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F6),
      appBar: AppBar(
        title: const Text('設定'),
        centerTitle: true,
        backgroundColor: const Color(0xFFFCF9F6),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                '資料管理 🌷',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF514A50),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(
                    Icons.download_rounded,
                    color: Color(0xFFAA8BCB),
                  ),
                  title: const Text('匯出飲食紀錄'),
                  subtitle: const Text('將所有紀錄備份為 JSON 檔案'),
                  onTap: () => exportRecords(context),
                ),
              ),
              Card(
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(
                    Icons.upload_rounded,
                    color: Color(0xFFAA8BCB),
                  ),
                  title: const Text('匯入飲食紀錄'),
                  subtitle: const Text('從 JSON 備份檔案還原紀錄'),
                  onTap: () => importRecords(context),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  '讓每一天的小小努力，都被好好收藏 ♡',
                  style: TextStyle(
                    color: Color(0xFF9B9298),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
