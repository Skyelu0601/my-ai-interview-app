import { sendPromptToDeepSeek } from './deepseekService.js';
import Database from '../database/database.js';
import { v4 as uuidv4 } from 'uuid';

class QuestionGenerationService {
  constructor() {
    this.db = new Database();
    this.isInitialized = false;
  }

  async init() {
    if (!this.isInitialized) {
      await this.db.init();
      this.isInitialized = true;
    }
  }

  /**
   * 生成面试问题的核心方法
   * @param {string} industry - 行业
   * @param {string} role - 岗位
   * @param {number} count - 生成问题数量
   * @returns {Array} 生成的问题数组
   */
  async generateQuestions(industry, role, count = 10) {
    await this.init();

    const systemPrompt = `你是一名专业的HR专家，专门为${industry}行业的${role}岗位设计面试问题。

请生成${count}个高质量的面试问题，要求：
1. 问题类型多样化，包括：
   - behavior: 行为与经验类问题（如"请分享一个你处理过的困难项目"）
   - technical: 专业知识与技能类问题（如"请解释一下XXX技术的原理"）
   - situational: 情景假设类问题（如"如果遇到XXX情况，你会如何处理"）
   - motivation: 动机与匹配度问题（如"为什么选择我们公司"）

2. 每个问题应该：
   - 简洁明了，适合实际面试场景
   - 针对${role}岗位的特点设计
   - 能够有效评估候选人的能力

3. 输出格式：每个问题单独一行，格式为：[类型] 问题内容

示例：
[behavior] 请分享一个你在团队中解决冲突的经历
[technical] 请解释一下你熟悉的编程语言的特点
[situational] 如果项目deadline提前一周，你会如何调整计划
[motivation] 为什么选择这个行业和岗位`;

    const userPrompt = `请为${industry}行业的${role}岗位生成${count}个面试问题，按照上述要求输出。`;

    try {
      const response = await sendPromptToDeepSeek(userPrompt, {
        systemPrompt,
        temperature: 0.8,
        maxTokens: 2000,
      });

      return this.parseQuestions(response, industry, role);
    } catch (error) {
      console.error('生成问题失败:', error);
      throw error;
    }
  }

  /**
   * 解析AI生成的问题文本
   * @param {string} response - AI响应文本
   * @param {string} industry - 行业
   * @param {string} role - 岗位
   * @returns {Array} 解析后的问题数组
   */
  parseQuestions(response, industry, role) {
    const lines = response.split('\n').filter(line => line.trim());
    const questions = [];

    for (const line of lines) {
      const match = line.match(/^\[(\w+)\]\s*(.+)$/);
      if (match) {
        const [, type, text] = match;
        if (['behavior', 'technical', 'situational', 'motivation'].includes(type)) {
          questions.push({
            industry,
            role,
            question_text: text.trim(),
            question_type: type
          });
        }
      }
    }

    return questions;
  }

  /**
   * 异步生成任务的后台执行方法
   * @param {string} taskId - 任务ID
   * @param {string} industry - 行业
   * @param {string} role - 岗位
   * @param {number} targetCount - 目标生成数量
   */
  async executeGenerationTask(taskId, industry, role, targetCount = 50) {
    await this.init();

    try {
      console.log(`开始执行生成任务 ${taskId}: ${industry} - ${role}, 目标: ${targetCount}个问题`);

      let currentCount = 0;
      const batchSize = 10; // 每批生成10个问题

      while (currentCount < targetCount) {
        const remainingCount = targetCount - currentCount;
        const generateCount = Math.min(batchSize, remainingCount);

        console.log(`生成第 ${currentCount + 1}-${currentCount + generateCount} 个问题...`);

        const questions = await this.generateQuestions(industry, role, generateCount);
        
        if (questions.length > 0) {
          await this.db.addQuestions(questions);
          currentCount += questions.length;
          await this.db.updateGenerationTaskProgress(taskId, currentCount);
          
          console.log(`已生成 ${currentCount}/${targetCount} 个问题`);
        } else {
          console.log('本轮未生成有效问题，跳过');
        }

        // 避免过于频繁的API调用
        await new Promise(resolve => setTimeout(resolve, 1000));
      }

      await this.db.completeGenerationTask(taskId);
      console.log(`生成任务 ${taskId} 完成`);

    } catch (error) {
      console.error(`生成任务 ${taskId} 失败:`, error);
      await this.db.failGenerationTask(taskId, error.message);
    }
  }

  /**
   * 启动异步生成任务
   * @param {string} industry - 行业
   * @param {string} role - 岗位
   * @returns {string} 任务ID
   */
  async startGenerationTask(industry, role) {
    await this.init();

    // 检查是否已有进行中的任务
    const existingTask = await this.db.getActiveGenerationTask(industry, role);
    if (existingTask) {
      console.log(`行业 ${industry} 岗位 ${role} 已有进行中的生成任务: ${existingTask.task_id}`);
      return existingTask.task_id;
    }

    const taskId = uuidv4();
    const targetCount = parseInt(await this.db.getConfig('TARGET_QUESTIONS_TO_GENERATE')) || 50;

    // 创建任务记录
    await this.db.createGenerationTask(taskId, industry, role, targetCount);

    // 异步执行任务（不等待完成）
    this.executeGenerationTask(taskId, industry, role, targetCount).catch(error => {
      console.error(`后台生成任务执行失败:`, error);
    });

    return taskId;
  }

  /**
   * 获取生成任务状态
   * @param {string} taskId - 任务ID
   * @returns {Object} 任务状态信息
   */
  async getTaskStatus(taskId) {
    await this.init();
    return await this.db.getGenerationTask(taskId);
  }

  /**
   * 检查问题库是否足够开始面试
   * @param {string} industry - 行业
   * @param {string} role - 岗位
   * @returns {Object} 检查结果
   */
  async checkQuestionAvailability(industry, role) {
    await this.init();

    const currentCount = await this.db.getQuestionCount(industry, role);
    const minRequired = parseInt(await this.db.getConfig('MIN_QUESTIONS_TO_START')) || 5;
    const targetCount = parseInt(await this.db.getConfig('TARGET_QUESTIONS_TO_GENERATE')) || 50;

    const isAvailable = currentCount >= minRequired;
    const activeTask = await this.db.getActiveGenerationTask(industry, role);

    return {
      currentCount,
      minRequired,
      targetCount,
      isAvailable,
      activeTask: activeTask ? {
        taskId: activeTask.task_id,
        progress: activeTask.progress_current,
        target: activeTask.progress_target
      } : null
    };
  }
}

export default QuestionGenerationService;
