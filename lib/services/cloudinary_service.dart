// سرویس آپلود عکس و فایل به Cloudinary (به‌جای Firebase Storage)
// چون Firebase Storage نیاز به پلن Blaze (کارت بانکی) دارد،
// از Cloudinary که سطح رایگان بدون کارت دارد استفاده می‌کنیم.
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // این دو مقدار را از داشبورد Cloudinary خودتان گرفتید
  static const String cloudName = 'nhqclamj';
  static const String uploadPreset = 'Olom haftom veysi';

  static String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/auto/upload';

  /// آپلود یک فایل (عکس یا PDF) و بازگرداندن URL نهایی آن
  /// [folder] مثلاً: teachers/loghman-veisi یا images/chapter_1
  static Future<String> uploadFile(File file, {String? folder}) async {
    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
    request.fields['upload_preset'] = uploadPreset;
    if (folder != null) {
      request.fields['folder'] = folder;
    }
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('خطا در آپلود به Cloudinary: $body');
    }

    final data = jsonDecode(body);
    return data['secure_url'] as String;
  }
}
