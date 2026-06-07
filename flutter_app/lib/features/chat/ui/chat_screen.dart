import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/network/api_client.dart';
import '../../projects/data/projects_model.dart';

class ChatScreen extends StatefulWidget {
  final Project project;

  const ChatScreen({super.key, required this.project});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _client = ApiClient();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  List<Map<String, String>> _messages = [];

  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      final response = await _client.get(
        '/projects/${widget.project.id}/chats',
      );

      final List data = response is List ? response : [];

      setState(() {
        _messages = data
            .map(
              (m) => {
                'role': m['role'].toString(),
                'message': m['message'].toString(),
              },
            )
            .toList();

        _isLoading = false;
      });

      if (_messages.isEmpty) {
        setState(() {
          _messages.add({
            'role': 'ai',
            'message':
                'Hi! I\'m your AI assistant for the "${widget.project.name}" project. '
                'I can help you create and improve diagrams. '
                'What would you like to do?',
          });
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }

    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();

    if (text.isEmpty || _isSending) return;

    _controller.clear();

    setState(() {
      _messages.add({'role': 'user', 'message': text});

      _isSending = true;
    });

    _scrollToBottom();

    try {
      final response = await _client.post(
        '/projects/${widget.project.id}/chat',
        data: {'message': text},
      );

      setState(() {
        _messages.add({
          'role': 'ai',
          'message': response['reply'] ?? 'Sorry, something went wrong.',
        });

        _isSending = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'ai',
          'message': 'Connection error. Please try again.',
        });

        _isSending = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
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
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Assistant',
              style: TextStyle(
                fontSize: AppSizes.fontLg,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            Text(
              widget.project.name,
              style: TextStyle(
                fontSize: AppSizes.fontSm,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),

        actions: [
          Container(
            margin: EdgeInsets.only(right: AppSizes.md),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),

                const SizedBox(width: 4),

                Text(
                  'Online',
                  style: TextStyle(
                    fontSize: AppSizes.fontXs,
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          /// Messages
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(AppSizes.screenPadding),
                    itemCount: _messages.length + (_isSending ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == _messages.length) {
                        return _buildTypingIndicator();
                      }

                      return _buildMessage(_messages[i]);
                    },
                  ),
          ),

          /// Input
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, String> msg) {
    final isUser = msg['role'] == 'user';

    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.sm),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,

        crossAxisAlignment: CrossAxisAlignment.end,

        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(width: 8),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.surface,

                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),

                border: isUser ? null : Border.all(color: AppColors.border),
              ),

              child: Text(
                msg['message']!,
                style: TextStyle(
                  fontSize: AppSizes.fontSm,
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ),

          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.sm),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(0),
                const SizedBox(width: 4),
                _dot(200),
                const SizedBox(width: 4),
                _dot(400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + delay),

      builder: (_, v, __) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.textTertiary.withValues(alpha: v),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInput() {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSizes.screenPadding,
          AppSizes.sm,
          AppSizes.screenPadding,
          AppSizes.md,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,

                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppSizes.fontSm,
                ),

                maxLines: 4,
                minLines: 1,

                onSubmitted: (_) => _sendMessage(),

                decoration: InputDecoration(
                  hintText: 'Ask AI about your diagrams...',

                  hintStyle: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: AppSizes.fontSm,
                  ),

                  filled: true,
                  fillColor: AppColors.background,

                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusRound),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusRound),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusRound),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(width: AppSizes.sm),

            GestureDetector(
              onTap: _isSending ? null : _sendMessage,

              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),

                width: 44,
                height: 44,

                decoration: BoxDecoration(
                  color: _isSending ? AppColors.border : AppColors.primary,

                  borderRadius: BorderRadius.circular(22),

                  boxShadow: _isSending
                      ? []
                      : [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),

                child: _isSending
                    ? const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
