import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'onboarding_state.dart';

class InterviewerChatScreen extends ConsumerStatefulWidget {
  const InterviewerChatScreen({super.key});

  @override
  ConsumerState<InterviewerChatScreen> createState() => _InterviewerChatScreenState();
}

class _InterviewerChatScreenState extends ConsumerState<InterviewerChatScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _typingController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _typingAnimation;

  int _currentMessageIndex = 0;
  int _currentCharIndex = 0;
  bool _showStartButton = false;
  Timer? _charTimer;
  Timer? _messageTimer;
  List<String> _displayedMessages = [];
  List<String> _currentMessageTexts = [];

  final List<String> _messages = [
    '您好，我是面试官招才。',
    '今天将由我为您进行模拟面试。',
    '本次模拟面试将基于您提供的简历、申请的岗位以及行业特点量身定制。',
    '语音实战模式目前正在开发，敬请期待。',
    '如果您已准备好展现最好的自己，我们可以随时开始',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _typingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typingController,
      curve: Curves.easeInOut,
    ));

    _startMessageSequence();
  }

  void _startMessageSequence() {
    _showNextMessage();
  }

  void _showNextMessage() {
    if (_currentMessageIndex < _messages.length) {
      setState(() {
        _displayedMessages.add('');
        _currentMessageTexts.add('');
        _currentCharIndex = 0;
      });
      
      _animationController.reset();
      _animationController.forward();
      
      _startTyping();
    }
  }

  void _startTyping() {
    if (_currentCharIndex < _messages[_currentMessageIndex].length) {
      _charTimer = Timer(const Duration(milliseconds: 50), () {
        if (mounted) {
          setState(() {
            _currentMessageTexts[_currentMessageIndex] = 
                _messages[_currentMessageIndex].substring(0, _currentCharIndex + 1);
            _displayedMessages[_currentMessageIndex] = 
                _messages[_currentMessageIndex].substring(0, _currentCharIndex + 1);
            _currentCharIndex++;
          });
          _startTyping();
        }
      });
    } else {
      // 当前消息打字完成，立即开始下一个消息
      _messageTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _currentMessageIndex++;
          });
          if (_currentMessageIndex < _messages.length) {
            _showNextMessage();
          } else {
            _showStartButton = true;
            _typingController.forward();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _typingController.dispose();
    _messageTimer?.cancel();
    _charTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // 聊天标题栏
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 返回按钮
                  IconButton(
                    onPressed: () {
                      // 如果是从主界面进入的，则返回；如果是首次进入，则关闭应用
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        // 首次进入时，可以选择关闭应用或显示提示
                        SystemNavigator.pop();
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF1976D2),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 面试官头像
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/cat_interviewer.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 面试官名字
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '面试官招才',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          '在线',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF4CAF50),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 更多选项按钮
                  IconButton(
                    onPressed: () {
                      // 可以添加更多选项
                    },
                    icon: const Icon(
                      Icons.more_vert,
                      color: Color(0xFF666666),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            
            // 聊天界面
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // 面试官头像和消息列表
                    Expanded(
                      child: ListView.builder(
                        itemCount: _displayedMessages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 面试官头像
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: Image.asset(
                                      'assets/images/cat_interviewer.png',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(width: 16),
                                
                                // 消息气泡
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      _displayedMessages[index],
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: const Color(0xFF1A1A1A),
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 开始面试按钮
                    if (_showStartButton)
                      AnimatedBuilder(
                        animation: _typingAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _typingAnimation.value,
                            child: Opacity(
                              opacity: _typingAnimation.value,
                              child: SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: () {
                                    // 标记欢迎对话已看过，然后导航到onboarding
                                    ref.read(onboardingStateProvider.notifier).markWelcomeChatSeen();
                                    Navigator.pushReplacementNamed(context, '/onboarding');
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF1976D2),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: Text(
                                    '开始面试',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}