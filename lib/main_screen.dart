import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_flow.dart';
import 'practice_chat_screen.dart';
import 'onboarding_state.dart';
import 'auth_state.dart';
import 'interview_loading_screen.dart';
import 'mock_interview_screen.dart';
import 'profile_center_screen.dart';
import 'vip_center_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with TickerProviderStateMixin {
  late AnimationController _catAnimationController;
  late AnimationController _bubbleAnimationController;
  late Animation<double> _catScaleAnimation;
  late Animation<double> _bubbleFadeAnimation;
  late Animation<Offset> _bubbleSlideAnimation;

  bool _isVip = false;

  @override
  void initState() {
    super.initState();
    
    // 招才猫动画控制器
    _catAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // 对话气泡动画控制器
    _bubbleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // 招才猫缩放动画
    _catScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _catAnimationController,
      curve: Curves.elasticOut,
    ));

    // 对话气泡淡入动画
    _bubbleFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bubbleAnimationController,
      curve: Curves.easeInOut,
    ));

    // 对话气泡滑入动画
    _bubbleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _bubbleAnimationController,
      curve: Curves.easeOutBack,
    ));

    // 启动动画
    _catAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 800), () {
      _bubbleAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _catAnimationController.dispose();
    _bubbleAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部导航栏
            _buildTopNavigationBar(context),
            
            // 主内容区
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    
                    // 招才猫形象和对话气泡
                    _buildCatAndBubble(),
                    
                    const SizedBox(height: 60),
                    
                    // 核心功能按钮
                    _buildMainButtons(context),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavigationBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 用户中心
          GestureDetector(
            onTap: () => _showUserProfile(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person_outline,
                size: 24,
                color: Color(0xFF666666),
              ),
            ),
          ),
          
          const Spacer(),
          
          // 面试岗位选择
          Consumer(
            builder: (context, ref, child) {
              final onboardingState = ref.watch(onboardingStateProvider);
              final selectedPosition = onboardingState.targetRole ?? "产品经理";
              
              return GestureDetector(
                onTap: () => _showPositionSelector(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF1976D2).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedPosition,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 20,
                        color: Color(0xFF1976D2),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const Spacer(),
          
          // VIP中心
          GestureDetector(
            onTap: () => _showVipCenter(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isVip 
                    ? const Color(0xFFFFD700).withOpacity(0.2)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
                border: _isVip 
                    ? Border.all(color: const Color(0xFFFFD700), width: 1)
                    : null,
              ),
              child: Icon(
                Icons.account_balance_wallet,
                size: 24,
                color: _isVip 
                    ? const Color(0xFFFFD700)
                    : const Color(0xFF666666),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatAndBubble() {
    return Column(
      children: [
        // 对话气泡 - 放在顶部
        AnimatedBuilder(
          animation: _bubbleAnimationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _bubbleFadeAnimation,
              child: SlideTransition(
                position: _bubbleSlideAnimation,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 30),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: const Color(0xFF1976D2).withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    "准备好迎接挑战了吗？\n当前岗位面试真题已就绪！",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1976D2),
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
        ),
        
        // 招才猫形象
        AnimatedBuilder(
          animation: _catScaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _catScaleAnimation.value,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1976D2).withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.asset(
                    'assets/images/cat_interviewer.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // 如果图片不存在，显示一个占位符
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1976D2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Icon(
                          Icons.pets,
                          size: 80,
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
      ],
    );
  }

  Widget _buildMainButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          // 面试练习按钮
          _buildActionButton(
            context: context,
            title: "面试练习",
            subtitle: "无压力模拟，随时开始",
            icon: Icons.shield_outlined,
            color: const Color(0xFF4CAF50),
            onTap: () => _navigateToPractice(context),
          ),
          
          const SizedBox(height: 20),
          
          // 实战演练按钮
          _buildActionButton(
            context: context,
            title: "实战演练",
            subtitle: "真实环境挑战，检验成果",
            icon: Icons.flash_on,
            color: const Color(0xFF1976D2),
            onTap: () => _navigateToRealInterview(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 20,
              color: Colors.white.withOpacity(0.8),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProfileCenterScreen(),
      ),
    );
  }


  void _showPositionSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '选择面试岗位',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('产品经理'),
              onTap: () {
                ref.read(onboardingStateProvider.notifier).updateTargetRole('产品经理');
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('软件工程师'),
              onTap: () {
                ref.read(onboardingStateProvider.notifier).updateTargetRole('软件工程师');
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('律师'),
              onTap: () {
                ref.read(onboardingStateProvider.notifier).updateTargetRole('律师');
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('医生'),
              onTap: () {
                ref.read(onboardingStateProvider.notifier).updateTargetRole('医生');
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('重新设置'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SettingsFlow()),
                );
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('重新进行初始设置'),
              subtitle: const Text('重新填写个人信息和岗位偏好'),
              onTap: () {
                Navigator.of(context).pop();
                ref.read(onboardingStateProvider.notifier).resetOnboarding();
                Navigator.of(context).pushReplacementNamed('/onboarding');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showVipCenter(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const VipCenterScreen(),
      ),
    );
  }

  void _navigateToPractice(BuildContext context) {
    // 检查是否已完成onboarding
    final onboardingState = ref.read(onboardingStateProvider);
    if (onboardingState.isOnboardingCompleted) {
      // 已完成onboarding，直接显示等待界面然后跳转到面试
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const InterviewLoadingScreen(),
        ),
      );
      // 延迟跳转到面试界面
      Future.delayed(const Duration(milliseconds: 500), () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // 移除等待界面
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const MockInterviewScreen(),
          ),
        );
      });
    } else {
      // 未完成onboarding，跳转到练习界面
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const PracticeChatScreen(),
        ),
      );
    }
  }

  void _navigateToRealInterview(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('实战演练'),
        content: const Text('实战演练功能开发中，敬请期待！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
