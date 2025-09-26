import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { sendPromptToDeepSeek, sendPromptToDeepSeekStream } from './services/deepseekService.js';
import { buildPrompt, buildInterviewQuestionsPrompt, buildReferenceAnswerPrompt } from './services/promptBuilder.js';
import { sendSMS, verifyCode, generateVerificationCode } from './services/smsService.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 8787;

// Middlewares
app.use(cors());
app.use(express.json({ limit: '2mb' }));

// Health check
app.get('/health', (req, res) => {
  res.json({ ok: true, service: 'ai-interview-coach-server' });
});

// Generate interview questions endpoint
app.post('/api/interview/generate-questions', async (req, res) => {
  try {
    const { targetRole, resumeText, jobDescription, batchSize = 5, isFirstBatch = false, existingQuestions = [] } = req.body;
    
    if (!targetRole) {
      return res.status(400).json({ error: 'targetRole is required' });
    }

    const { systemPrompt, userPrompt } = buildInterviewQuestionsPrompt({
      targetRole,
      resumeText,
      jobDescription,
      batchSize,
      isFirstBatch,
      existingQuestions,
    });

    const response = await sendPromptToDeepSeek(userPrompt, {
      systemPrompt,
      temperature: 0.8,
      maxTokens: 2000,
      debug: true,
    });

    // Parse the JSON response
    let questions;
    try {
      // Extract JSON from markdown code block if present
      let jsonString = response;
      const jsonMatch = response.match(/```json\s*([\s\S]*?)\s*```/);
      if (jsonMatch) {
        jsonString = jsonMatch[1];
      }
      
      questions = JSON.parse(jsonString);
      if (!Array.isArray(questions)) {
        throw new Error('Response is not an array');
      }
    } catch (parseError) {
      console.error('Failed to parse questions response:', response);
      console.error('Parse error:', parseError.message);
      // Fallback: create default questions
      questions = [
        '你好！欢迎参加今天的面试。我是招才，今天将由我来主持你的面试。首先，请你简单地做个自我介绍吧。',
        '请介绍一下你在相关领域的工作经验。',
        '你认为自己最大的优势是什么？',
        '请描述一次你解决复杂问题的经历。',
        '你对这个岗位有什么期望？',
      ].slice(0, batchSize);
    }

    res.json({ questions });
  } catch (error) {
    console.error('Error generating questions:', error);
    res.status(500).json({ error: 'Failed to generate questions' });
  }
});

// Generate reference answer endpoint (streaming)
app.post('/api/interview/generate-answer', async (req, res) => {
  try {
    const { question, targetRole, resumeText, jobDescription } = req.body;
    
    if (!question || !targetRole) {
      return res.status(400).json({ error: 'question and targetRole are required' });
    }

    const { systemPrompt, userPrompt } = buildReferenceAnswerPrompt({
      question,
      targetRole,
      resumeText,
      jobDescription,
    });

    // Set headers for streaming
    res.setHeader('Content-Type', 'text/plain');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');

    await sendPromptToDeepSeekStream(userPrompt, {
      systemPrompt,
      temperature: 0.7,
      maxTokens: 1000,
      debug: true,
      onChunk: (chunk) => {
        res.write(`data: ${JSON.stringify({ content: chunk })}\n\n`);
      },
    });

    res.write('data: [DONE]\n\n');
    res.end();
  } catch (error) {
    console.error('Error generating answer:', error);
    res.status(500).json({ error: 'Failed to generate answer' });
  }
});

// 发送验证码短信
app.post('/api/auth/send-sms', async (req, res) => {
  try {
    const { phoneNumber } = req.body;
    
    if (!phoneNumber) {
      return res.status(400).json({ error: '手机号不能为空' });
    }

    // 验证手机号格式
    const phoneRegex = /^1[3-9]\d{9}$/;
    if (!phoneRegex.test(phoneNumber)) {
      return res.status(400).json({ error: '请输入正确的手机号' });
    }

    const result = await sendSMS(phoneNumber);
    
    if (result.success) {
      res.json({ 
        success: true, 
        message: '验证码发送成功',
        // 开发环境下返回验证码，生产环境应该移除
        code: result.code // 总是返回验证码，方便开发调试
      });
    } else {
      res.status(400).json({ 
        success: false, 
        message: result.message || '发送失败' 
      });
    }
  } catch (error) {
    console.error('Error sending SMS:', error);
    res.status(500).json({ error: '发送验证码失败' });
  }
});

// 验证验证码并登录
app.post('/api/auth/verify-code', async (req, res) => {
  try {
    const { phoneNumber, code } = req.body;
    
    if (!phoneNumber || !code) {
      return res.status(400).json({ error: '手机号和验证码不能为空' });
    }

    const result = await verifyCode(phoneNumber, code);
    
    if (result.success) {
      res.json({ 
        success: true, 
        message: '登录成功',
        token: result.token,
        user: {
          phoneNumber: phoneNumber,
          loginTime: new Date().toISOString()
        }
      });
    } else {
      res.status(400).json({ 
        success: false, 
        message: result.message || '验证码错误' 
      });
    }
  } catch (error) {
    console.error('Error verifying code:', error);
    res.status(500).json({ error: '验证失败' });
  }
});

// 验证token中间件
const verifyToken = (req, res, next) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  
  if (!token) {
    return res.status(401).json({ error: '未提供认证token' });
  }
  
  // 这里应该验证token的有效性
  // 暂时简单验证
  if (token.startsWith('token_')) {
    req.user = { token };
    next();
  } else {
    res.status(401).json({ error: '无效的token' });
  }
};

// 需要认证的接口示例
app.get('/api/user/profile', verifyToken, (req, res) => {
  res.json({
    success: true,
    user: {
      phoneNumber: req.user.phoneNumber || '138****8888',
      loginTime: new Date().toISOString()
    }
  });
});

app.listen(PORT, () => {
  console.log(`Server listening on http://localhost:${PORT}`);
});

export default app;