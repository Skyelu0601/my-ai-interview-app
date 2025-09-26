/**
 * Prompt builder for AI services
 * This file will be used to build prompts for different AI functionalities
 */

/**
 * Build a prompt for interview question generation
 * @param {object} params - Parameters for building the prompt
 * @returns {{ systemPrompt: string, userPrompt: string }}
 */
export function buildInterviewQuestionsPrompt(params = {}) {
  const { targetRole, resumeText, jobDescription, batchSize = 5, isFirstBatch = false, existingQuestions = [] } = params;
  
  const existingQuestionsText = existingQuestions.length > 0 ? 
    `\n已生成的问题（避免重复）：\n${existingQuestions.map((q, i) => `${i + 1}. ${q}`).join('\n')}` : '';
  
  const systemPrompt = `你是一名专业AI面试官「招才」，扮演资深HR专家。请基于以下背景信息生成高质量的面试问题。

面试背景：
1. 目标岗位：${targetRole}
2. 候选人简历：${resumeText || '未提供简历信息'}
3. 岗位描述：${jobDescription || '未提供岗位描述'}${existingQuestionsText}

生成要求：
${isFirstBatch ? '1. 首题固定：「你好！欢迎参加今天的面试。我是招才，今天将由我来主持你的面试。首先，请你简单地做个自我介绍吧。」' : '1. 不要包含自我介绍问题，这是后续批次的问题生成'}
2. 问题类型配比（建议）：
   - 行为经验类（40%）：针对简历细节提问
   - 专业知识类（30%）：考察岗位硬技能
   - 情景假设类（30%）：设置典型工作场景
3. 问题总数：${batchSize}个，保持自然对话流
4. 问题要具体、有针对性，避免泛泛而谈
5. 语言要专业但友好，符合面试官身份
6. 确保每个问题都是独特的，避免重复
7. 问题内容要多样化，避免相似表述
8. 每个问题都要有不同的角度和侧重点`;

  const userPrompt = `请生成${batchSize}个面试问题，以JSON数组格式返回，每个问题为一个字符串元素。`;

  return { systemPrompt, userPrompt };
}

/**
 * Build a prompt for reference answer generation
 * @param {object} params - Parameters for building the prompt
 * @returns {{ systemPrompt: string, userPrompt: string }}
 */
export function buildReferenceAnswerPrompt(params = {}) {
  const { question, targetRole, resumeText, jobDescription } = params;
  
  const systemPrompt = `你正在参加${targetRole}的面试。请根据以下背景信息生成专业、自然的口语化回答。

面试背景：
1. 应聘岗位：${targetRole}
2. 我的简历：${resumeText || '未提供简历信息'}
3. 岗位要求：${jobDescription || '未提供岗位描述'}

生成要求：
1. 回答需体现专业性且符合实际经验
2. 语言保持口语化，避免书面化表达
3. 重点突出与岗位的匹配度
4. 长度适中（约150-300字）
5. 回答要具体、有实例，避免空洞
6. 体现候选人的能力和经验
7. 使用纯文本格式，不要使用任何Markdown格式符号（如**、*、#等）
8. 直接输出回答内容，不要添加任何格式标记`;

  const userPrompt = `面试问题：${question}

请生成一个高质量的参考答案。注意：请使用纯文本格式，不要使用任何Markdown格式符号（如**、*、#等），直接输出回答内容即可。`;

  return { systemPrompt, userPrompt };
}

/**
 * Build a prompt for AI service (legacy)
 * @param {object} params - Parameters for building the prompt
 * @returns {{ systemPrompt: string, userPrompt: string }}
 */
export function buildPrompt(params = {}) {
  // TODO: Implement prompt building logic based on new requirements
  const systemPrompt = 'You are a helpful AI assistant.';
  const userPrompt = 'Please help me with my request.';
  
  return { systemPrompt, userPrompt };
}

export default { 
  buildPrompt, 
  buildInterviewQuestionsPrompt, 
  buildReferenceAnswerPrompt 
};

