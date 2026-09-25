// سرویس ارتباط با دستیار هوش مصنوعی (Cloudflare Workers AI)
// این نسخه به‌جای OpenAI مستقیم، از واسط امن Cloudflare Worker استفاده می‌کند
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class AiAssistantService {
  // آدرس Worker خودتان در Cloudflare
  static const String _workerUrl = 'https://oloom-ai.loghman-veysi.workers.dev';

  /// ارسال تاریخچه پیام‌ها و دریافت پاسخ دستیار
  /// [messages] لیستی از Map با فیلدهای role ('user' یا 'assistant') و content
  static Future<String> sendMessage(List<Map<String, String>> messages) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('برای استفاده از دستیار هوشمند باید وارد حساب شوید.');
    }

    final token = await user.getIdToken();

    final response = await http.post(
      Uri.parse(_workerUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'messages': messages}),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200) {
      throw Exception(
          'خطا (کد ${response.statusCode}): ${data['error'] ?? 'نامشخص'} ${data['detail'] ?? ''}');
    }
    if (data['error'] != null) {
      throw Exception('خطا: ${data['error']} ${data['detail'] ?? ''}');
    }
    return data['reply'] ?? '';
  }
}
