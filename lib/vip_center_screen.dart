import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'interview_state.dart';

class VipCenterScreen extends ConsumerStatefulWidget {
  const VipCenterScreen({super.key});

  @override
  ConsumerState<VipCenterScreen> createState() => _VipCenterScreenState();
}

class _VipCenterScreenState extends ConsumerState<VipCenterScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final interviewSession = ref.watch(interviewStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('VIP中心'),
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
            // VIP状态卡片
            _buildVipStatusCard(theme, interviewSession),
            
            const SizedBox(height: 20),
            
            // 充值套餐
            _buildRechargePlans(theme),
            
            const SizedBox(height: 20),
            
            // VIP特权说明
            _buildVipBenefits(theme),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildVipStatusCard(ThemeData theme, interviewSession) {
    final isVip = interviewSession?.isPaidSession == true;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isVip 
              ? [const Color(0xFFFFD700), const Color(0xFFFFA000)]
              : [const Color(0xFF1976D2), const Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isVip ? const Color(0xFFFFD700) : const Color(0xFF1976D2)).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  isVip ? Icons.diamond : Icons.account_balance_wallet,
                  size: 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isVip ? 'VIP会员' : '普通用户',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isVip ? '享受无限制面试时长' : '免费30分钟面试时长',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              if (isVip)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'VIP',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          
          if (!isVip) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '升级VIP，享受更多特权',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 无限制面试时长\n• 专属客服支持\n• 高级面试题库\n• 面试报告分析',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRechargePlans(ThemeData theme) {
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
              '充值套餐',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
          
          _buildRechargePlan(
            theme,
            title: '月度VIP',
            price: '¥29',
            duration: '30天',
            features: ['无限制面试时长', '专属客服支持', '高级面试题库'],
            isPopular: true,
            onTap: () => _showPaymentDialog('月度VIP', 29),
          ),
          
          _buildRechargePlan(
            theme,
            title: '季度VIP',
            price: '¥79',
            duration: '90天',
            features: ['无限制面试时长', '专属客服支持', '高级面试题库', '面试报告分析'],
            isPopular: false,
            onTap: () => _showPaymentDialog('季度VIP', 79),
          ),
          
          _buildRechargePlan(
            theme,
            title: '年度VIP',
            price: '¥299',
            duration: '365天',
            features: ['无限制面试时长', '专属客服支持', '高级面试题库', '面试报告分析', '一对一面试指导'],
            isPopular: false,
            onTap: () => _showPaymentDialog('年度VIP', 299),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRechargePlan(
    ThemeData theme, {
    required String title,
    required String price,
    required String duration,
    required List<String> features,
    required bool isPopular,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      if (isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5722),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '推荐',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    duration,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: const Color(0xFF4CAF50),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          feature,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                Text(
                  price,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '立即购买',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVipBenefits(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
          Text(
            'VIP特权',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          
          _buildBenefitItem(
            theme,
            icon: Icons.all_inclusive,
            title: '无限制面试时长',
            description: '不受时间限制，随时进行面试练习',
          ),
          
          _buildBenefitItem(
            theme,
            icon: Icons.support_agent,
            title: '专属客服支持',
            description: '7x24小时在线客服，快速解决问题',
          ),
          
          _buildBenefitItem(
            theme,
            icon: Icons.quiz,
            title: '高级面试题库',
            description: '涵盖各行业最新面试题目，持续更新',
          ),
          
          _buildBenefitItem(
            theme,
            icon: Icons.analytics,
            title: '面试报告分析',
            description: '详细的面试表现分析和改进建议',
          ),
          
          _buildBenefitItem(
            theme,
            icon: Icons.person_pin,
            title: '一对一面试指导',
            description: '专业面试官一对一指导（年度VIP专享）',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String description,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFFFFD700),
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
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(String planName, int price) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('购买$planName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('套餐：$planName'),
            const SizedBox(height: 8),
            Text('价格：¥$price'),
            const SizedBox(height: 16),
            const Text('支付方式：'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _processPayment(planName, price, 'wechat'),
                    icon: const Icon(Icons.chat, color: Color(0xFF4CAF50)),
                    label: const Text('微信支付'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _processPayment(planName, price, 'alipay'),
                    icon: const Icon(Icons.payment, color: Color(0xFF1976D2)),
                    label: const Text('支付宝'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _processPayment(String planName, int price, String paymentMethod) {
    Navigator.of(context).pop(); // 关闭支付对话框
    
    // 显示支付处理中
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('正在处理${paymentMethod == 'wechat' ? '微信' : '支付宝'}支付...'),
          ],
        ),
      ),
    );
    
    // 模拟支付处理
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop(); // 关闭处理中对话框
      
      // 模拟支付成功，升级为VIP
      ref.read(interviewStateProvider.notifier).upgradeToPaidSession();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('支付成功'),
          content: Text('恭喜您成功购买$planName！\n\n您现在是VIP会员，可以享受无限制面试时长。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // 返回个人中心
              },
              child: const Text('确定'),
            ),
          ],
        ),
      );
    });
  }
}
