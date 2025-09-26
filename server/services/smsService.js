import crypto from 'crypto';

// 内存存储验证码（生产环境应该使用Redis等持久化存储）
const verificationCodes = new Map();

// 生成6位数字验证码
export function generateVerificationCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// 发送短信验证码
export async function sendSMS(phoneNumber) {
  try {
    // 检查发送频率限制（开发环境10秒，生产环境1分钟）
    const lastSendTime = verificationCodes.get(`${phoneNumber}_last_send`);
    const now = Date.now();
    const cooldownTime = process.env.NODE_ENV === 'development' ? 10000 : 60000;
    
    if (lastSendTime && (now - lastSendTime) < cooldownTime) {
      return {
        success: false,
        message: `发送过于频繁，请${cooldownTime / 1000}秒后再试`
      };
    }

    // 生成验证码
    const code = generateVerificationCode();
    
    // 存储验证码（5分钟有效期）
    verificationCodes.set(phoneNumber, {
      code: code,
      timestamp: now,
      attempts: 0
    });
    
    // 记录发送时间
    verificationCodes.set(`${phoneNumber}_last_send`, now);

    // 这里应该调用真实的短信服务API
    // 目前返回模拟结果
    const result = await sendSMSWithProvider(phoneNumber, code);
    
    if (result.success) {
      return {
        success: true,
        message: '验证码发送成功',
        code: code // 开发环境返回验证码，生产环境应该移除
      };
    } else {
      return {
        success: false,
        message: result.message || '发送失败'
      };
    }
  } catch (error) {
    console.error('Send SMS error:', error);
    return {
      success: false,
      message: '发送验证码失败'
    };
  }
}

// 验证验证码
export async function verifyCode(phoneNumber, inputCode) {
  try {
    const storedData = verificationCodes.get(phoneNumber);
    
    if (!storedData) {
      return {
        success: false,
        message: '验证码不存在或已过期'
      };
    }

    // 检查验证码是否过期（5分钟）
    const now = Date.now();
    if (now - storedData.timestamp > 300000) {
      verificationCodes.delete(phoneNumber);
      return {
        success: false,
        message: '验证码已过期，请重新获取'
      };
    }

    // 检查尝试次数（最多3次）
    if (storedData.attempts >= 3) {
      verificationCodes.delete(phoneNumber);
      return {
        success: false,
        message: '验证码错误次数过多，请重新获取'
      };
    }

    // 验证验证码
    if (storedData.code !== inputCode) {
      storedData.attempts++;
      verificationCodes.set(phoneNumber, storedData);
      return {
        success: false,
        message: `验证码错误，还有${3 - storedData.attempts}次机会`
      };
    }

    // 验证成功，删除验证码
    verificationCodes.delete(phoneNumber);
    verificationCodes.delete(`${phoneNumber}_last_send`);

    // 生成JWT token（简化版本）
    const token = generateToken(phoneNumber);

    return {
      success: true,
      message: '验证成功',
      token: token
    };
  } catch (error) {
    console.error('Verify code error:', error);
    return {
      success: false,
      message: '验证失败'
    };
  }
}

// 调用短信服务提供商
async function sendSMSWithProvider(phoneNumber, code) {
  // 这里可以集成不同的短信服务提供商
  
  // 方法1: 聚合数据短信服务
  // return await sendWithJuhe(phoneNumber, code);
  
  // 方法2: 阿里云短信服务
  // return await sendWithAliyun(phoneNumber, code);
  
  // 方法3: 腾讯云短信服务
  // return await sendWithTencent(phoneNumber, code);
  
  // 目前返回模拟成功
  console.log(`模拟发送短信到 ${phoneNumber}，验证码：${code}`);
  
  // 模拟网络延迟
  await new Promise(resolve => setTimeout(resolve, 1000));
  
  return {
    success: true,
    message: '短信发送成功'
  };
}

// 聚合数据短信服务
async function sendWithJuhe(phoneNumber, code) {
  const apiKey = process.env.JUHE_SMS_API_KEY;
  const templateId = process.env.JUHE_SMS_TEMPLATE_ID;
  
  if (!apiKey || !templateId) {
    throw new Error('聚合数据短信服务配置不完整');
  }

  const response = await fetch('http://v.juhe.cn/sms/send', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      mobile: phoneNumber,
      tpl_id: templateId,
      tpl_value: `#code#=${code}`,
      key: apiKey,
    }),
  });

  const data = await response.json();
  
  if (data.error_code === 0) {
    return { success: true, message: '发送成功' };
  } else {
    return { success: false, message: data.reason || '发送失败' };
  }
}

// 阿里云短信服务
async function sendWithAliyun(phoneNumber, code) {
  // 这里需要实现阿里云的签名算法
  // 建议使用阿里云官方SDK
  const accessKeyId = process.env.ALIYUN_ACCESS_KEY_ID;
  const accessKeySecret = process.env.ALIYUN_ACCESS_KEY_SECRET;
  const signName = process.env.ALIYUN_SMS_SIGN_NAME;
  const templateCode = process.env.ALIYUN_SMS_TEMPLATE_CODE;
  
  if (!accessKeyId || !accessKeySecret || !signName || !templateCode) {
    throw new Error('阿里云短信服务配置不完整');
  }

  // 实现阿里云短信发送逻辑
  // 这里需要实现签名算法，比较复杂
  // 建议使用 @alicloud/dysmsapi20170525 官方SDK
  
  return { success: true, message: '发送成功' };
}

// 腾讯云短信服务
async function sendWithTencent(phoneNumber, code) {
  const secretId = process.env.TENCENT_SECRET_ID;
  const secretKey = process.env.TENCENT_SECRET_KEY;
  const appId = process.env.TENCENT_SMS_APP_ID;
  const templateId = process.env.TENCENT_SMS_TEMPLATE_ID;
  const signName = process.env.TENCENT_SMS_SIGN_NAME;
  
  if (!secretId || !secretKey || !appId || !templateId || !signName) {
    throw new Error('腾讯云短信服务配置不完整');
  }

  // 实现腾讯云短信发送逻辑
  // 建议使用 tencentcloud-sdk-nodejs 官方SDK
  
  return { success: true, message: '发送成功' };
}

// 生成简单的JWT token
function generateToken(phoneNumber) {
  const header = {
    alg: 'HS256',
    typ: 'JWT'
  };
  
  const payload = {
    phoneNumber: phoneNumber,
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + (7 * 24 * 60 * 60) // 7天过期
  };
  
  const encodedHeader = Buffer.from(JSON.stringify(header)).toString('base64url');
  const encodedPayload = Buffer.from(JSON.stringify(payload)).toString('base64url');
  
  const signature = crypto
    .createHmac('sha256', process.env.JWT_SECRET || 'your-secret-key')
    .update(`${encodedHeader}.${encodedPayload}`)
    .digest('base64url');
  
  return `token_${encodedHeader}.${encodedPayload}.${signature}`;
}

// 验证JWT token
export function verifyToken(token) {
  try {
    if (!token.startsWith('token_')) {
      return null;
    }
    
    const tokenParts = token.replace('token_', '').split('.');
    if (tokenParts.length !== 3) {
      return null;
    }
    
    const [encodedHeader, encodedPayload, signature] = tokenParts;
    
    // 验证签名
    const expectedSignature = crypto
      .createHmac('sha256', process.env.JWT_SECRET || 'your-secret-key')
      .update(`${encodedHeader}.${encodedPayload}`)
      .digest('base64url');
    
    if (signature !== expectedSignature) {
      return null;
    }
    
    // 解析payload
    const payload = JSON.parse(Buffer.from(encodedPayload, 'base64url').toString());
    
    // 检查过期时间
    if (payload.exp < Math.floor(Date.now() / 1000)) {
      return null;
    }
    
    return payload;
  } catch (error) {
    console.error('Token verification error:', error);
    return null;
  }
}
