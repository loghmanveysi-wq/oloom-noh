// صفحه چت با دستیار هوش مصنوعی علوم نهم
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/ai_assistant_service.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _ChatMessage {
  final String role; // 'user' یا 'assistant'
  final String content;
  _ChatMessage(this.role, this.content);
}

class _AiChatScreenState extends State<AiChatScreen> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _loading = false;

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _messages.add(_ChatMessage('user', text));
      _inputController.clear();
      _loading = true;
    });
    _scrollToEnd();

    try {
      final history = _messages
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();
      final reply = await AiAssistantService.sendMessage(history);
      setState(() {
        _messages.add(_ChatMessage('assistant', reply));
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage('assistant', 'متأسفم، مشکلی پیش آمد: $e'));
      });
    } finally {
      setState(() => _loading = false);
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دستیار هوشمند علوم')),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'سلام! من دستیار هوشمند علوم نهم هستم.\nهر سؤالی درباره درس علوم داری بپرس 🌱',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg.role == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.grey.shade200 : AppTheme.primaryBlue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(msg.content, style: const TextStyle(fontSize: 15)),
                        ),
                      );
                    },
                  ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: SizedBox(
                height: 18, width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: InputDecoration(
                        hintText: 'سؤال خود را بنویس...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppTheme.accentOrange,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
