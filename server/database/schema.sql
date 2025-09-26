-- 面试问题库表
CREATE TABLE IF NOT EXISTS question_bank (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    industry VARCHAR(100) NOT NULL,
    role VARCHAR(100) NOT NULL,
    question_text TEXT NOT NULL,
    question_type VARCHAR(50) NOT NULL CHECK (question_type IN ('behavior', 'technical', 'situational', 'motivation')),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_question_bank_industry_role ON question_bank (industry, role);
CREATE INDEX IF NOT EXISTS idx_question_bank_created_at ON question_bank (created_at);

-- 异步生成任务表
CREATE TABLE IF NOT EXISTS generation_tasks (
    task_id VARCHAR(100) PRIMARY KEY,
    industry VARCHAR(100) NOT NULL,
    role VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'processing' CHECK (status IN ('processing', 'completed', 'failed')),
    progress_current INTEGER DEFAULT 0,
    progress_target INTEGER DEFAULT 50,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME NULL,
    error_message TEXT NULL
);

CREATE INDEX IF NOT EXISTS idx_generation_tasks_status ON generation_tasks (status);
CREATE INDEX IF NOT EXISTS idx_generation_tasks_industry_role ON generation_tasks (industry, role);

-- 面试会话表
CREATE TABLE IF NOT EXISTS interview_sessions (
    session_id VARCHAR(100) PRIMARY KEY,
    user_id VARCHAR(100) NULL,
    industry VARCHAR(100) NOT NULL,
    role VARCHAR(100) NOT NULL,
    question_set TEXT NOT NULL, -- JSON array of question IDs
    current_index INTEGER DEFAULT 0,
    start_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    end_time DATETIME NULL,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'over_time')),
    billing_triggered BOOLEAN DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_interview_sessions_user_id ON interview_sessions (user_id);
CREATE INDEX IF NOT EXISTS idx_interview_sessions_start_time ON interview_sessions (start_time);
CREATE INDEX IF NOT EXISTS idx_interview_sessions_status ON interview_sessions (status);

-- 系统配置表
CREATE TABLE IF NOT EXISTS system_config (
    config_key VARCHAR(100) PRIMARY KEY,
    config_value TEXT NOT NULL,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 插入默认配置
INSERT OR REPLACE INTO system_config (config_key, config_value) VALUES 
('MIN_QUESTIONS_TO_START', '5'),
('TARGET_QUESTIONS_TO_GENERATE', '50'),
('INTERVIEW_QUESTION_SET_SIZE', '20'),
('BILLING_TIME_LIMIT_MINUTES', '30');
