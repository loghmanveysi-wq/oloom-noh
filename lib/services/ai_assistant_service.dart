// سرویس ارتباط با OpenAI API برای دستیار هوشمند علوم
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AiAssistantService {
  // ⚠️ کلید API را هرگز مستقیم در کد قرار ندهید؛
  // از Firebase Remote Config یا یک Cloud Function واسط استفاده کنید
  // تا کلید در اپ منتشرشده قابل مشاهده نباشد.
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  Future<String> askQuestion(String question, {required String apiKey}) async {
    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content': 'تو دستیار آموزشی علوم تجربی پایه نهم هستی. به فارسی و ساده پاسخ بده.'
          },
          {'role': 'user', 'content': question},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('خطا در دریافت پاسخ از دستیار هوشمند');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final answer = data['choices'][0]['message']['content'] as String;

    // ذخیره سؤال و پاسخ برای پنل دبیر
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('aiQuestions')
        .add({
      'question': question,
      'answer': answer,
      'timestamp': FieldValue.serverTimestamp(),
    });

    return answer;
  }
}
