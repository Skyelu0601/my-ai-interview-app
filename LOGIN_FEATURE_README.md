# 面试关 - 手机号验证码登录功能

## 功能概述

面试关应用现已集成手机号验证码登录功能，用户可以通过输入手机号获取验证码来完成登录。

## 功能特点

- ✅ 支持中国手机号格式验证
- ✅ 验证码发送频率限制（开发环境10秒，生产环境1分钟）
- ✅ 验证码有效期5分钟
- ✅ 验证码尝试次数限制（最多3次）
- ✅ 自动保存登录状态
- ✅ 支持登出功能
- ✅ 美观的登录界面设计

## 使用方法

### 1. 启动应用

```bash
# 使用开发脚本启动（推荐）
./start_dev.sh

# 或手动启动
# 启动后端服务
cd server
NODE_ENV=development npm start

# 启动Flutter应用
cd ..
flutter run
```

### 2. 登录流程

1. **输入手机号**：在登录界面输入11位中国手机号
2. **获取验证码**：点击"获取验证码"按钮
3. **输入验证码**：输入收到的6位数字验证码
4. **完成登录**：点击"验证登录"按钮

### 3. 测试模式

在开发环境下，应用支持测试模式：

- 输入任意11位手机号（如：13800138000）
- 点击"获取验证码"
- 在API响应中查看返回的验证码
- 输入该验证码完成登录

### 4. 登出功能

- 点击主界面右上角的用户头像
- 选择"退出登录"
- 确认退出即可返回登录界面

## 技术实现

### 前端架构

- **状态管理**：使用Riverpod管理登录状态
- **本地存储**：使用SharedPreferences保存登录信息
- **UI组件**：使用intl_phone_field支持国际化手机号输入
- **网络请求**：使用http包调用后端API

### 后端架构

- **框架**：Express.js
- **验证码存储**：内存存储（生产环境建议使用Redis）
- **JWT认证**：使用JWT token进行用户认证
- **API设计**：RESTful API设计

### API接口

#### 发送验证码
```
POST /api/auth/send-sms
Content-Type: application/json

{
  "phoneNumber": "13800138000"
}

Response:
{
  "success": true,
  "message": "验证码发送成功",
  "code": "123456"  // 仅开发环境返回
}
```

#### 验证登录
```
POST /api/auth/verify-code
Content-Type: application/json

{
  "phoneNumber": "13800138000",
  "code": "123456"
}

Response:
{
  "success": true,
  "message": "登录成功",
  "token": "token_...",
  "user": {
    "phoneNumber": "13800138000",
    "loginTime": "2025-01-23T06:28:17.121Z"
  }
}
```

#### 获取用户信息
```
GET /api/user/profile
Authorization: Bearer <token>

Response:
{
  "success": true,
  "user": {
    "phoneNumber": "138****8888",
    "loginTime": "2025-01-23T06:28:25.878Z"
  }
}
```

## 生产环境部署

### 1. 短信服务配置

参考 `SMS_SETUP_GUIDE.md` 配置真实的短信服务：

- 聚合数据短信服务（推荐）
- 阿里云短信服务
- 腾讯云短信服务

### 2. 环境变量配置

创建 `.env` 文件：

```env
NODE_ENV=production
JWT_SECRET=your-super-secret-jwt-key
JUHE_SMS_API_KEY=your_api_key
JUHE_SMS_TEMPLATE_ID=your_template_id
```

### 3. 安全注意事项

- 使用强JWT密钥
- 配置HTTPS
- 设置适当的CORS策略
- 使用Redis等持久化存储验证码
- 配置日志监控

## 故障排除

### 常见问题

1. **验证码发送失败**
   - 检查后端服务是否启动
   - 确认API密钥配置正确
   - 检查网络连接

2. **验证码验证失败**
   - 确认验证码未过期
   - 检查验证码格式
   - 确认未超过尝试次数

3. **登录状态丢失**
   - 检查SharedPreferences权限
   - 确认token未过期

### 调试方法

1. **查看后端日志**：后端服务会在控制台输出详细日志
2. **检查网络请求**：使用浏览器开发者工具查看API请求
3. **Flutter调试**：使用Flutter Inspector查看UI状态

## 开发计划

- [ ] 集成真实短信服务
- [ ] 添加用户头像上传
- [ ] 实现密码登录选项
- [ ] 添加第三方登录（微信、QQ）
- [ ] 实现用户资料管理
- [ ] 添加登录日志记录

## 贡献指南

欢迎提交Issue和Pull Request来改进登录功能！

## 许可证

本项目采用MIT许可证。

