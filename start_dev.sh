#!/bin/bash

# 启动开发环境脚本

echo "🚀 启动面试关开发环境..."

# 设置环境变量
export NODE_ENV=development

# 启动后端服务
echo "📡 启动后端服务..."
cd server
NODE_ENV=development npm start &
BACKEND_PID=$!

# 等待后端服务启动
echo "⏳ 等待后端服务启动..."
sleep 3

# 检查后端服务是否正常
if curl -s http://localhost:8787/health > /dev/null; then
    echo "✅ 后端服务启动成功"
    echo "📋 使用说明："
    echo "   - 输入任意11位手机号（如：13800138000）"
    echo "   - 点击获取验证码"
    echo "   - 在终端查看返回的验证码"
    echo "   - 输入验证码完成登录"
else
    echo "❌ 后端服务启动失败"
    kill $BACKEND_PID
    exit 1
fi

# 启动Flutter应用
echo "📱 启动Flutter应用..."
cd ..
flutter run

# 清理：当Flutter应用退出时，停止后端服务
echo "🛑 停止后端服务..."
kill $BACKEND_PID
