# 短信验证码服务配置指南

## 概述

本应用已集成手机号验证码登录功能，支持多种短信服务提供商。以下是配置步骤：

## 1. 环境变量配置

在项目根目录创建 `.env` 文件，添加以下配置：

```env
# 后端服务配置
PORT=8787
NODE_ENV=development

# JWT密钥（生产环境请使用强密码）
JWT_SECRET=your-super-secret-jwt-key-here

# 短信服务配置 - 聚合数据（推荐）
JUHE_SMS_API_KEY=your_juhe_api_key_here
JUHE_SMS_TEMPLATE_ID=your_template_id_here

# 短信服务配置 - 阿里云
ALIYUN_ACCESS_KEY_ID=your_access_key_id
ALIYUN_ACCESS_KEY_SECRET=your_access_key_secret
ALIYUN_SMS_SIGN_NAME=your_sign_name
ALIYUN_SMS_TEMPLATE_CODE=your_template_code

# 短信服务配置 - 腾讯云
TENCENT_SECRET_ID=your_secret_id
TENCENT_SECRET_KEY=your_secret_key
TENCENT_SMS_APP_ID=your_app_id
TENCENT_SMS_TEMPLATE_ID=your_template_id
TENCENT_SMS_SIGN_NAME=your_sign_name

# DeepSeek API配置
DEEPSEEK_API_KEY=your_deepseek_api_key_here
```

## 2. 短信服务提供商选择

### 推荐：聚合数据短信服务

**优点：**
- 配置简单，易于集成
- 价格便宜
- 支持多种模板

**申请步骤：**
1. 访问 [聚合数据短信服务](https://www.juhe.cn/docs/api/id/54)
2. 注册账号并实名认证
3. 申请短信服务，获取API Key
4. 创建短信模板，获取模板ID
5. 配置到环境变量中

**费用：** 约0.05元/条

### 阿里云短信服务

**优点：**
- 功能强大，稳定性高
- 支持多种签名和模板
- 企业级服务

**申请步骤：**
1. 访问 [阿里云短信服务控制台](https://dysms.console.aliyun.com/)
2. 开通短信服务
3. 创建签名（需要企业资质）
4. 创建短信模板
5. 获取AccessKey ID和AccessKey Secret
6. 配置到环境变量中

**费用：** 约0.045元/条

### 腾讯云短信服务

**优点：**
- 腾讯生态集成好
- 功能丰富
- 稳定性高

**申请步骤：**
1. 访问 [腾讯云短信服务](https://cloud.tencent.com/product/sms)
2. 开通短信服务
3. 创建应用
4. 创建签名和模板
5. 获取SecretId和SecretKey
6. 配置到环境变量中

**费用：** 约0.045元/条

## 3. 测试模式

在开发环境中，应用支持测试模式：

- 输入任意11位手机号
- 验证码输入 `123456` 即可登录
- 后端会返回模拟的验证码

## 4. 生产环境部署

### 安全注意事项

1. **JWT密钥**：使用强密码，建议32位以上随机字符串
2. **API密钥**：妥善保管，不要提交到代码仓库
3. **HTTPS**：生产环境必须使用HTTPS
4. **验证码限制**：已实现发送频率限制（1分钟1次）和尝试次数限制（3次）

### 部署步骤

1. 配置生产环境的环境变量
2. 启动后端服务：`npm start`
3. 构建Flutter应用：`flutter build apk` 或 `flutter build ios`
4. 部署到服务器或应用商店

## 5. API接口说明

### 发送验证码
```
POST /api/auth/send-sms
Content-Type: application/json

{
  "phoneNumber": "13800138000"
}
```

### 验证登录
```
POST /api/auth/verify-code
Content-Type: application/json

{
  "phoneNumber": "13800138000",
  "code": "123456"
}
```

### 用户信息
```
GET /api/user/profile
Authorization: Bearer <token>
```

## 6. 故障排除

### 常见问题

1. **验证码发送失败**
   - 检查API密钥配置
   - 确认短信服务商账户余额
   - 检查手机号格式

2. **验证码验证失败**
   - 确认验证码未过期（5分钟有效期）
   - 检查验证码格式（6位数字）
   - 确认未超过尝试次数限制

3. **后端服务连接失败**
   - 检查后端服务是否启动
   - 确认端口配置正确
   - 检查网络连接

### 日志查看

后端服务会在控制台输出详细日志，包括：
- 短信发送状态
- 验证码验证结果
- 错误信息

## 7. 费用预估

以聚合数据为例：
- 注册用户：1000人
- 每人平均登录：10次/月
- 总短信量：10,000条/月
- 费用：约500元/月

建议根据实际用户量选择合适的套餐。

