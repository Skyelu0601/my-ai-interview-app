import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'auth_state.dart';
import 'interview_state.dart';
import 'vip_center_screen.dart';

class ProfileCenterScreen extends ConsumerStatefulWidget {
  const ProfileCenterScreen({super.key});

  @override
  ConsumerState<ProfileCenterScreen> createState() => _ProfileCenterScreenState();
}

class _ProfileCenterScreenState extends ConsumerState<ProfileCenterScreen> {
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      // 如果获取版本信息失败，使用默认版本
      setState(() {
        _appVersion = '1.0.0';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final interviewSession = ref.watch(interviewStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('个人中心'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 用户信息卡片
            _buildUserInfoCard(theme, authState, interviewSession),
            
            const SizedBox(height: 20),
            
            // 支持与帮助
            _buildSupportSection(theme),
            
            const SizedBox(height: 20),
            
            // 退出登录按钮
            _buildLogoutButton(theme),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(ThemeData theme, AuthState authState, interviewSession) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.person,
                  size: 30,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '用户ID',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authState.phoneNumber ?? '未设置',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 剩余面试时长
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: const Color(0xFF4CAF50),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '剩余面试时长',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF4CAF50),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getRemainingTimeText(interviewSession),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF4CAF50),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (interviewSession?.isPaidSession == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'VIP',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  // 充值按钮
                  InkWell(
                    onTap: () => _navigateToVipCenter(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '充值',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              '支持与帮助',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
          
          _buildSupportItem(
            theme,
            icon: Icons.info_outline,
            title: '软件版本',
            subtitle: 'v$_appVersion',
            onTap: () => _showVersionInfo(),
          ),
          
          _buildSupportItem(
            theme,
            icon: Icons.feedback_outlined,
            title: '问题反馈',
            subtitle: '遇到问题？告诉我们',
            onTap: () => _showFeedbackDialog(),
          ),
          
          _buildSupportItem(
            theme,
            icon: Icons.description_outlined,
            title: '用户协议',
            subtitle: '查看用户使用协议',
            onTap: () => _showUserAgreement(),
          ),
          
          _buildSupportItem(
            theme,
            icon: Icons.privacy_tip_outlined,
            title: '隐私政策',
            subtitle: '了解我们如何保护您的隐私',
            onTap: () => _showPrivacyPolicy(),
          ),
          
          _buildSupportItem(
            theme,
            icon: Icons.help_outline,
            title: '其他',
            subtitle: '更多帮助信息',
            onTap: () => _showOtherHelp(),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSupportItem(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: isLast ? null : Border(
            bottom: BorderSide(
              color: const Color(0xFFE0E0E0),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: const Color(0xFF1976D2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: const Color(0xFFCCCCCC),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _showLogoutDialog(),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Color(0xFFFF5722)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          '退出登录',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: const Color(0xFFFF5722),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _getRemainingTimeText(interviewSession) {
    if (interviewSession?.isPaidSession == true) {
      return '无限制';
    }
    
    if (interviewSession?.freeTimeRemaining != null) {
      final remaining = interviewSession!.freeTimeRemaining!;
      final minutes = remaining.inMinutes;
      final seconds = remaining.inSeconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    
    return '30:00';
  }

  void _showVersionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('软件版本'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前版本：v$_appVersion'),
            const SizedBox(height: 8),
            const Text('招才猫 - 智能面试助手'),
            const SizedBox(height: 8),
            const Text('© 2024 招才猫团队'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('问题反馈'),
        content: const Text('感谢您的反馈！\n\n您可以通过以下方式联系我们：\n\n• 邮箱：feedback@zhaocaimao.com\n• 微信：zhaocaimao_support\n• 电话：400-123-4567'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showUserAgreement() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('用户协议'),
        content: const SingleChildScrollView(
          child: Text(
            '用户协议\n\n'
            '欢迎使用招才猫智能面试助手！\n\n'
            '1. 服务条款\n'
            '本应用为用户提供智能面试练习服务，用户在使用过程中应遵守相关法律法规。\n\n'
            '2. 用户责任\n'
            '用户应确保提供信息的真实性和准确性，不得利用本服务进行任何违法活动。\n\n'
            '3. 服务变更\n'
            '我们保留随时修改或终止服务的权利，恕不另行通知。\n\n'
            '4. 免责声明\n'
            '本服务仅供参考，不构成任何形式的建议或承诺。\n\n'
            '最后更新：2024年1月',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('隐私政策'),
        content: const SingleChildScrollView(
          child: Text(
            '隐私政策\n\n'
            '我们重视您的隐私保护，本政策说明了我们如何收集、使用和保护您的个人信息。\n\n'
            '1. 信息收集\n'
            '我们仅收集必要的用户信息，包括手机号码和简历内容，用于提供面试服务。\n\n'
            '2. 信息使用\n'
            '您的信息仅用于提供个性化面试练习服务，不会用于其他商业目的。\n\n'
            '3. 信息保护\n'
            '我们采用行业标准的安全措施保护您的个人信息安全。\n\n'
            '4. 信息共享\n'
            '我们不会向第三方分享您的个人信息，除非获得您的明确同意。\n\n'
            '5. 您的权利\n'
            '您有权查看、修改或删除您的个人信息。\n\n'
            '最后更新：2024年1月',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showOtherHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('其他帮助'),
        content: const Text(
          '常见问题：\n\n'
          'Q: 如何开始面试练习？\n'
          'A: 在主界面选择"面试练习"即可开始。\n\n'
          'Q: 免费时长用完了怎么办？\n'
          'A: 可以升级到VIP版本获得无限制使用。\n\n'
          'Q: 如何修改个人信息？\n'
          'A: 在主界面点击岗位选择，选择"重新设置"。\n\n'
          '更多问题请联系客服。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _navigateToVipCenter() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const VipCenterScreen(),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？退出后需要重新登录才能使用。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // 关闭对话框
              
              // 显示加载指示器
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              try {
                // 执行退出登录
                await ref.read(authStateProvider.notifier).logout();
                
                if (mounted) {
                  // 关闭加载指示器
                  Navigator.of(context).pop();
                  
                  // 导航到登录页面，清除所有之前的页面
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login', 
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  // 关闭加载指示器
                  Navigator.of(context).pop();
                  
                  // 显示错误信息
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('退出登录失败: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
