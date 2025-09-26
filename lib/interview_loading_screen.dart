import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'onboarding_state.dart';

class InterviewLoadingScreen extends ConsumerStatefulWidget {
  const InterviewLoadingScreen({super.key});

  @override
  ConsumerState<InterviewLoadingScreen> createState() => _InterviewLoadingScreenState();
}

class _InterviewLoadingScreenState extends ConsumerState<InterviewLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _fadeController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    // 脉冲动画控制器
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // 旋转动画控制器
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // 淡入动画控制器
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // 进度条动画控制器 - 模拟真实的加载进度
    _progressController = AnimationController(
      duration: const Duration(seconds: 12), // 12秒完成，更符合实际生成速度
      vsync: this,
    );

    // 脉冲动画
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // 旋转动画
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.linear,
    ));

    // 淡入动画
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // 进度条动画 - 使用分段曲线模拟真实加载过程
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 0.95, // 最多到95%，避免100%后还在等待
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutQuart, // 使用更快的曲线，前半段快，后半段慢
    ));

    // 启动动画
    _fadeController.forward();
    _pulseController.repeat(reverse: true);
    _rotateController.repeat();
    _progressController.forward(); // 启动进度条动画
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _fadeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onboardingState = ref.watch(onboardingStateProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // 顶部导航栏
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
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Color(0xFF1976D2),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '面试关',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          Text(
                            '目标岗位：${onboardingState.targetRole}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 主内容区域
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 面试官头像和动画
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(60),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1976D2).withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(60),
                                child: Image.asset(
                                  'assets/images/cat_interviewer.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1976D2).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(60),
                                      ),
                                      child: const Icon(
                                        Icons.pets,
                                        size: 60,
                                        color: Color(0xFF1976D2),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // 加载指示器
                      AnimatedBuilder(
                        animation: _rotateAnimation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotateAnimation.value * 2 * 3.14159,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1976D2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.psychology,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // 标题
                      Text(
                        '正在为您准备面试问题',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 描述文字
                      Text(
                        '基于您的简历和岗位要求，我们正在生成个性化的面试问题，请稍候...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF666666),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // 进度指示器
                      Container(
                        width: double.infinity,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Stack(
                          children: [
                            // 背景进度条
                            AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                return FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: _progressAnimation.value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF1976D2),
                                          Color(0xFF42A5F5),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF1976D2).withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            // 移动的光点效果
                            AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                return Positioned(
                                  left: (_progressAnimation.value * (MediaQuery.of(context).size.width - 48)) - 4,
                                  top: 0,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF1976D2).withOpacity(0.5),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 进度百分比和提示文字
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          final percentage = (_progressAnimation.value * 100).round();
                          return Column(
                            children: [
                              Text(
                                '$percentage%',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: const Color(0xFF1976D2),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                percentage < 15 
                                    ? '正在分析您的简历...'
                                    : percentage < 35
                                        ? '正在理解岗位要求...'
                                        : percentage < 55
                                            ? '正在生成个性化问题...'
                                            : percentage < 75
                                                ? '正在优化问题难度...'
                                                : percentage < 90
                                                    ? '正在完善面试内容...'
                                                    : '即将完成，请稍候...',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF666666),
                                ),
                              ),
                            ],
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
      ),
    );
  }
}
