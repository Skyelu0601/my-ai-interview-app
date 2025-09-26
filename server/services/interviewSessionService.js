import Database from '../database/database.js';
import { v4 as uuidv4 } from 'uuid';

class InterviewSessionService {
  constructor() {
    this.db = new Database();
    this.isInitialized = false;
    
    // 预定义的反馈语数组
    this.feedbackPhrases = [
      "好的。",
      "明白了。",
      "有趣的经验。",
      "谢谢分享。",
      "我了解了。",
      "这是一个很好的角度。",
      "能具体谈谈你当时是怎么想的吗？",
      "我明白你的意思了。",
      "很有意思的经历。",
      "好的，那我们接下来谈谈..."
    ];
  }

  async init() {
    if (!this.isInitialized) {
      await this.db.init();
      this.isInitialized = true;
    }
  }

  /**
   * 开始面试会话
   * @param {string} userId - 用户ID（可选）
   * @param {string} industry - 行业
   * @param {string} role - 岗位
   * @returns {Object} 面试会话信息
   */
  async startInterview(userId, industry, role) {
    await this.init();

    const questionSetSize = parseInt(await this.db.getConfig('INTERVIEW_QUESTION_SET_SIZE')) || 20;
    
    // 获取随机问题集
    const questions = await this.db.getRandomQuestions(industry, role, questionSetSize);
    
    if (questions.length === 0) {
      throw new Error('问题库中没有足够的问题');
    }

    const sessionId = uuidv4();
    const questionSet = questions.map(q => ({
      id: q.id,
      text: q.question_text,
      type: q.question_type
    }));

    // 创建面试会话
    await this.db.createInterviewSession(sessionId, userId, industry, role, questionSet);

    return {
      sessionId,
      industry,
      role,
      questionSet,
      currentIndex: 0,
      startTime: new Date().toISOString(),
      totalQuestions: questionSet.length
    };
  }

  /**
   * 获取下一个问题
   * @param {string} sessionId - 会话ID
   * @returns {Object} 下一个问题信息
   */
  async getNextQuestion(sessionId) {
    await this.init();

    const session = await this.db.getInterviewSession(sessionId);
    if (!session) {
      throw new Error('面试会话不存在');
    }

    if (session.status !== 'active') {
      throw new Error('面试会话已结束');
    }

    const currentIndex = session.current_index;
    const questionSet = session.question_set;

    if (currentIndex >= questionSet.length) {
      // 面试结束
      await this.db.completeInterviewSession(sessionId);
      return {
        isComplete: true,
        message: "面试已完成，感谢您的参与！"
      };
    }

    const currentQuestion = questionSet[currentIndex];
    
    // 检查是否需要触发计费
    const billingTriggered = await this.checkAndTriggerBilling(sessionId);

    // 准备返回的问题
    let questionText = currentQuestion.text;
    
    // 如果不是第一个问题，添加随机反馈
    if (currentIndex > 0) {
      const randomFeedback = this.feedbackPhrases[Math.floor(Math.random() * this.feedbackPhrases.length)];
      questionText = `${randomFeedback} ${questionText}`;
    }

    // 更新当前问题索引
    await this.db.updateInterviewSessionIndex(sessionId, currentIndex + 1);

    return {
      isComplete: false,
      question: {
        id: currentQuestion.id,
        text: questionText,
        type: currentQuestion.type,
        index: currentIndex + 1,
        total: questionSet.length
      },
      billingTriggered,
      sessionInfo: {
        sessionId,
        industry: session.industry,
        role: session.role,
        startTime: session.start_time
      }
    };
  }

  /**
   * 检查并触发计费
   * @param {string} sessionId - 会话ID
   * @returns {boolean} 是否触发了计费
   */
  async checkAndTriggerBilling(sessionId) {
    const session = await this.db.getInterviewSession(sessionId);
    if (!session || session.billing_triggered) {
      return session?.billing_triggered || false;
    }

    const billingTimeLimit = parseInt(await this.db.getConfig('BILLING_TIME_LIMIT_MINUTES')) || 30;
    const startTime = new Date(session.start_time);
    const currentTime = new Date();
    const elapsedMinutes = (currentTime - startTime) / (1000 * 60);

    if (elapsedMinutes >= billingTimeLimit) {
      await this.db.triggerBillingForSession(sessionId);
      return true;
    }

    return false;
  }

  /**
   * 获取面试会话信息
   * @param {string} sessionId - 会话ID
   * @returns {Object} 会话信息
   */
  async getSessionInfo(sessionId) {
    await this.init();
    return await this.db.getInterviewSession(sessionId);
  }

  /**
   * 结束面试会话
   * @param {string} sessionId - 会话ID
   * @returns {boolean} 是否成功结束
   */
  async endInterview(sessionId) {
    await this.init();
    const changes = await this.db.completeInterviewSession(sessionId);
    return changes > 0;
  }

  /**
   * 获取面试进度
   * @param {string} sessionId - 会话ID
   * @returns {Object} 进度信息
   */
  async getInterviewProgress(sessionId) {
    await this.init();
    const session = await this.db.getInterviewSession(sessionId);
    
    if (!session) {
      throw new Error('面试会话不存在');
    }

    const startTime = new Date(session.start_time);
    const currentTime = new Date();
    const elapsedMinutes = (currentTime - startTime) / (1000 * 60);
    const billingTimeLimit = parseInt(await this.db.getConfig('BILLING_TIME_LIMIT_MINUTES')) || 30;

    return {
      sessionId,
      currentIndex: session.current_index,
      totalQuestions: session.question_set.length,
      progress: Math.round((session.current_index / session.question_set.length) * 100),
      elapsedMinutes: Math.round(elapsedMinutes),
      billingTimeLimit,
      billingTriggered: session.billing_triggered,
      status: session.status,
      startTime: session.start_time
    };
  }

  /**
   * 获取随机反馈语
   * @returns {string} 随机反馈语
   */
  getRandomFeedback() {
    return this.feedbackPhrases[Math.floor(Math.random() * this.feedbackPhrases.length)];
  }
}

export default InterviewSessionService;
