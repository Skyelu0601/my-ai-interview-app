import sqlite3 from 'sqlite3';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

class Database {
  constructor() {
    this.db = null;
  }

  async init() {
    return new Promise((resolve, reject) => {
      const dbPath = path.join(__dirname, 'interview_system.db');
      this.db = new sqlite3.Database(dbPath, (err) => {
        if (err) {
          console.error('数据库连接失败:', err);
          reject(err);
        } else {
          console.log('数据库连接成功');
          this.createTables().then(resolve).catch(reject);
        }
      });
    });
  }

  async createTables() {
    const fs = await import('fs');
    const schemaPath = path.join(__dirname, 'schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf8');
    
    return new Promise((resolve, reject) => {
      this.db.exec(schema, (err) => {
        if (err) {
          console.error('创建表失败:', err);
          reject(err);
        } else {
          console.log('数据库表创建成功');
          resolve();
        }
      });
    });
  }

  // 问题库相关操作
  async getQuestionCount(industry, role) {
    return new Promise((resolve, reject) => {
      const sql = 'SELECT COUNT(*) as count FROM question_bank WHERE industry = ? AND role = ?';
      this.db.get(sql, [industry, role], (err, row) => {
        if (err) reject(err);
        else resolve(row.count);
      });
    });
  }

  async getRandomQuestions(industry, role, limit) {
    return new Promise((resolve, reject) => {
      const sql = 'SELECT * FROM question_bank WHERE industry = ? AND role = ? ORDER BY RANDOM() LIMIT ?';
      this.db.all(sql, [industry, role, limit], (err, rows) => {
        if (err) reject(err);
        else resolve(rows);
      });
    });
  }

  async addQuestions(questions) {
    return new Promise((resolve, reject) => {
      const sql = 'INSERT INTO question_bank (industry, role, question_text, question_type) VALUES (?, ?, ?, ?)';
      const stmt = this.db.prepare(sql);
      
      let completed = 0;
      let hasError = false;
      
      questions.forEach(question => {
        stmt.run([question.industry, question.role, question.question_text, question.question_type], (err) => {
          if (err && !hasError) {
            hasError = true;
            reject(err);
            return;
          }
          completed++;
          if (completed === questions.length && !hasError) {
            stmt.finalize();
            resolve();
          }
        });
      });
    });
  }

  // 生成任务相关操作
  async createGenerationTask(taskId, industry, role, targetCount = 50) {
    return new Promise((resolve, reject) => {
      const sql = 'INSERT INTO generation_tasks (task_id, industry, role, progress_target) VALUES (?, ?, ?, ?)';
      this.db.run(sql, [taskId, industry, role, targetCount], function(err) {
        if (err) reject(err);
        else resolve(this.lastID);
      });
    });
  }

  async getGenerationTask(taskId) {
    return new Promise((resolve, reject) => {
      const sql = 'SELECT * FROM generation_tasks WHERE task_id = ?';
      this.db.get(sql, [taskId], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });
  }

  async updateGenerationTaskProgress(taskId, currentCount) {
    return new Promise((resolve, reject) => {
      const sql = 'UPDATE generation_tasks SET progress_current = ? WHERE task_id = ?';
      this.db.run(sql, [currentCount, taskId], function(err) {
        if (err) reject(err);
        else resolve(this.changes);
      });
    });
  }

  async completeGenerationTask(taskId) {
    return new Promise((resolve, reject) => {
      const sql = 'UPDATE generation_tasks SET status = ?, completed_at = CURRENT_TIMESTAMP WHERE task_id = ?';
      this.db.run(sql, ['completed', taskId], function(err) {
        if (err) reject(err);
        else resolve(this.changes);
      });
    });
  }

  async failGenerationTask(taskId, errorMessage) {
    return new Promise((resolve, reject) => {
      const sql = 'UPDATE generation_tasks SET status = ?, error_message = ?, completed_at = CURRENT_TIMESTAMP WHERE task_id = ?';
      this.db.run(sql, ['failed', errorMessage, taskId], function(err) {
        if (err) reject(err);
        else resolve(this.changes);
      });
    });
  }

  async getActiveGenerationTask(industry, role) {
    return new Promise((resolve, reject) => {
      const sql = 'SELECT * FROM generation_tasks WHERE industry = ? AND role = ? AND status = ?';
      this.db.get(sql, [industry, role, 'processing'], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });
  }

  // 面试会话相关操作
  async createInterviewSession(sessionId, userId, industry, role, questionSet) {
    return new Promise((resolve, reject) => {
      const sql = 'INSERT INTO interview_sessions (session_id, user_id, industry, role, question_set) VALUES (?, ?, ?, ?, ?)';
      this.db.run(sql, [sessionId, userId, industry, role, JSON.stringify(questionSet)], function(err) {
        if (err) reject(err);
        else resolve(this.lastID);
      });
    });
  }

  async getInterviewSession(sessionId) {
    return new Promise((resolve, reject) => {
      const sql = 'SELECT * FROM interview_sessions WHERE session_id = ?';
      this.db.get(sql, [sessionId], (err, row) => {
        if (err) reject(err);
        else {
          if (row) {
            row.question_set = JSON.parse(row.question_set);
          }
          resolve(row);
        }
      });
    });
  }

  async updateInterviewSessionIndex(sessionId, currentIndex) {
    return new Promise((resolve, reject) => {
      const sql = 'UPDATE interview_sessions SET current_index = ? WHERE session_id = ?';
      this.db.run(sql, [currentIndex, sessionId], function(err) {
        if (err) reject(err);
        else resolve(this.changes);
      });
    });
  }

  async completeInterviewSession(sessionId) {
    return new Promise((resolve, reject) => {
      const sql = 'UPDATE interview_sessions SET status = ?, end_time = CURRENT_TIMESTAMP WHERE session_id = ?';
      this.db.run(sql, ['completed', sessionId], function(err) {
        if (err) reject(err);
        else resolve(this.changes);
      });
    });
  }

  async triggerBillingForSession(sessionId) {
    return new Promise((resolve, reject) => {
      const sql = 'UPDATE interview_sessions SET billing_triggered = TRUE, status = ? WHERE session_id = ?';
      this.db.run(sql, ['over_time', sessionId], function(err) {
        if (err) reject(err);
        else resolve(this.changes);
      });
    });
  }

  // 系统配置相关操作
  async getConfig(key) {
    return new Promise((resolve, reject) => {
      const sql = 'SELECT config_value FROM system_config WHERE config_key = ?';
      this.db.get(sql, [key], (err, row) => {
        if (err) reject(err);
        else resolve(row ? row.config_value : null);
      });
    });
  }

  async setConfig(key, value) {
    return new Promise((resolve, reject) => {
      const sql = 'INSERT OR REPLACE INTO system_config (config_key, config_value, updated_at) VALUES (?, ?, CURRENT_TIMESTAMP)';
      this.db.run(sql, [key, value], function(err) {
        if (err) reject(err);
        else resolve(this.changes);
      });
    });
  }

  close() {
    if (this.db) {
      this.db.close();
    }
  }
}

export default Database;
