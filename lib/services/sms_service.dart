import 'dart:convert';
import 'package:http/http.dart' as http;

class SMSService {
  // 这里可以配置不同的短信服务提供商
  // 推荐使用阿里云、腾讯云、或聚合数据等国内服务商
  
  // 阿里云短信服务配置示例
  static const String _aliyunAccessKeyId = 'YOUR_ACCESS_KEY_ID';
  static const String _aliyunAccessKeySecret = 'YOUR_ACCESS_KEY_SECRET';
  static const String _aliyunSignName = 'YOUR_SIGN_NAME';
  static const String _aliyunTemplateCode = 'YOUR_TEMPLATE_CODE';
  
  // 聚合数据短信服务配置示例
  static const String _juheApiKey = 'YOUR_JUHE_API_KEY';
  static const String _juheTemplateId = 'YOUR_TEMPLATE_ID';
  
  // 发送验证码短信
  static Future<Map<String, dynamic>> sendVerificationCode(String phoneNumber) async {
    try {
      // 方法1: 使用聚合数据短信服务（推荐，简单易用）
      return await _sendWithJuhe(phoneNumber);
      
      // 方法2: 使用阿里云短信服务（功能更强大）
      // return await _sendWithAliyun(phoneNumber);
      
    } catch (e) {
      return {
        'success': false,
        'message': '发送短信失败: $e',
      };
    }
  }

  // 使用聚合数据发送短信
  static Future<Map<String, dynamic>> _sendWithJuhe(String phoneNumber) async {
    const url = 'http://v.juhe.cn/sms/send';
    
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'mobile': phoneNumber,
        'tpl_id': _juheTemplateId,
        'tpl_value': '#code#=123456', // 这里应该生成随机验证码
        'key': _juheApiKey,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['error_code'] == 0) {
        return {
          'success': true,
          'message': '验证码发送成功',
          'code': '123456', // 实际应用中应该返回生成的验证码
        };
      } else {
        return {
          'success': false,
          'message': data['reason'] ?? '发送失败',
        };
      }
    } else {
      return {
        'success': false,
        'message': '网络请求失败',
      };
    }
  }

  // 使用阿里云发送短信
  static Future<Map<String, dynamic>> _sendWithAliyun(String phoneNumber) async {
    // 这里需要实现阿里云短信服务的签名和请求逻辑
    // 由于阿里云的签名算法比较复杂，建议使用官方SDK
    
    // 模拟实现
    await Future.delayed(const Duration(seconds: 1));
    
    return {
      'success': true,
      'message': '验证码发送成功（阿里云）',
      'code': '123456',
    };
  }

  // 生成随机验证码
  static String generateVerificationCode() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return (random % 900000 + 100000).toString(); // 生成6位数字验证码
  }

  // 验证手机号格式
  static bool isValidPhoneNumber(String phoneNumber) {
    // 中国手机号正则表达式
    final regex = RegExp(r'^1[3-9]\d{9}$');
    return regex.hasMatch(phoneNumber);
  }
}

// 短信服务配置说明
class SMSConfig {
  // 聚合数据短信服务申请步骤：
  // 1. 访问 https://www.juhe.cn/docs/api/id/54
  // 2. 注册账号并申请短信服务
  // 3. 获取API Key和模板ID
  // 4. 配置到上面的常量中
  
  // 阿里云短信服务申请步骤：
  // 1. 访问 https://dysms.console.aliyun.com/
  // 2. 开通短信服务
  // 3. 创建签名和模板
  // 4. 获取AccessKey ID和AccessKey Secret
  // 5. 配置到上面的常量中
  
  // 其他可选服务商：
  // - 腾讯云短信：https://cloud.tencent.com/product/sms
  // - 网易云信：https://yunxin.163.com/
  // - 容联云通讯：https://www.yuntongxun.com/
}

