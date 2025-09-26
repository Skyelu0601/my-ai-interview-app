import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _codeSent = false;
  int _countdown = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    if (_countdown > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _countdown--;
          });
          _startCountdown();
        }
      });
    }
  }

  void _sendCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final phoneNumber = '+86' + _phoneController.text;
    await ref.read(authStateProvider.notifier).sendVerificationCode(phoneNumber);
    
    final authState = ref.read(authStateProvider);
    
    setState(() {
      _isLoading = false;
    });

    if (authState.error == null) {
      setState(() {
        _codeSent = true;
        _countdown = 60;
      });
      _startCountdown();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('验证码已发送'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.error!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final phoneNumber = '+86' + _phoneController.text;
    await ref.read(authStateProvider.notifier).verifyCodeAndLogin(_codeController.text);
    
    final authState = ref.read(authStateProvider);
    
    setState(() {
      _isLoading = false;
    });

    if (authState.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.error!),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    // 如果登录成功，不需要显示错误消息，应用会自动跳转到主界面
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo区域
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.business_center,
                    size: 60,
                    color: Color(0xFF1976D2),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // 标题
                Text(
                  '招才猫',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                    letterSpacing: 1.2,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Text(
                  '专业面试训练平台',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // 登录表单
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 手机号输入
                        Text(
                          '手机号',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    right: BorderSide(color: Color(0xFFE0E0E0)),
                                  ),
                                ),
                                child: const Text(
                                  '+86',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: '请输入11位手机号',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    hintStyle: TextStyle(
                                      color: Color(0xFF999999),
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '请输入手机号';
                                    }
                                    if (value.length != 11) {
                                      return '请输入正确的11位手机号';
                                    }
                                    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
                                      return '请输入有效的手机号';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // 验证码输入（仅在发送验证码后显示）
                        if (_codeSent) ...[
                          Text(
                            '验证码',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: '请输入6位验证码',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              hintStyle: const TextStyle(
                                color: Color(0xFF999999),
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入验证码';
                              }
                              if (value.length != 6) {
                                return '请输入6位验证码';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                        ],

                        // 按钮区域
                        if (!_codeSent) ...[
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _sendCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1976D2),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      '获取验证码',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: OutlinedButton(
                                    onPressed: _countdown > 0 ? null : _sendCode,
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      _countdown > 0 ? '${_countdown}s后重发' : '重新发送',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _verifyCode,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1976D2),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Text(
                                            '验证登录',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
              ],
            ),
          ),
        ),
      ),
    );
  }
}
