# 部分练习进度记录功能

## 功能概述

为了解决用户可能在完成50题之前就退出的问题，我们实现了一个完整的部分练习进度记录系统。现在即使用户没有完成完整的面试，系统也会记录他们的练习时长、完成的题目数量，并在首页显示这些信息。

## 主要功能

### 1. 自动保存部分练习进度
- 当用户退出面试界面时，系统会自动保存当前的练习进度
- 记录练习时长、完成的题目数量、目标岗位等信息
- 支持多个未完成的练习会话

### 2. 首页统计显示
- 在首页的学习统计区域显示总练习时长（包括部分练习）
- 显示总练习题目数（包括部分练习）
- 显示未完成练习的数量和进度

### 3. 未完成练习管理
- 在首页显示最新的未完成练习会话
- 显示完成率、已完成的题目数、练习时长
- 提供"继续练习"按钮，可以恢复未完成的练习

### 4. 恢复练习功能
- 点击"继续练习"按钮可以恢复之前的练习会话
- 自动定位到用户上次停止的题目
- 保持之前的练习进度和状态

## 技术实现

### 新增文件
- `lib/partial_practice_manager.dart` - 部分练习会话管理器

### 修改的文件
- `lib/interview_state.dart` - 添加保存和恢复部分练习的方法
- `lib/learning_stats_manager.dart` - 扩展学习统计，支持部分练习记录
- `lib/learning_stats_widget.dart` - 更新首页统计显示，添加未完成练习区域
- `lib/mock_interview_screen.dart` - 在用户退出时自动保存进度

### 核心类和方法

#### PartialPracticeSession
```dart
class PartialPracticeSession {
  final String sessionId;
  final String targetRole;
  final DateTime startTime;
  final DateTime? lastActiveTime;
  final int completedQuestions;
  final int totalQuestionsGenerated;
  final Duration totalDuration;
  final List<String> completedQuestionIds;
  final bool isCompleted;
}
```

#### 主要方法
- `savePartialProgress()` - 保存部分练习进度
- `restoreFromPartialSession()` - 恢复部分练习会话
- `recordPartialPractice()` - 记录部分练习到学习统计
- `_resumePractice()` - 恢复练习的UI交互

## 用户体验改进

### 1. 进度可视化
- 在首页显示未完成练习的进度条
- 显示完成百分比和具体数据
- 清晰的视觉反馈

### 2. 便捷恢复
- 一键恢复未完成的练习
- 自动定位到上次停止的位置
- 保持练习的连续性

### 3. 统计完整性
- 所有练习时间都被记录，无论是否完成
- 提供更准确的学习数据
- 激励用户继续练习

## 数据持久化

- 使用SharedPreferences存储部分练习会话数据
- 自动保存和加载，无需用户手动操作
- 支持多个未完成会话的管理

## 使用场景

1. **用户中途退出**：系统自动保存进度，用户下次可以继续
2. **网络中断**：即使网络问题导致退出，进度也会被保存
3. **应用崩溃**：在dispose方法中保存进度，确保数据不丢失
4. **多设备使用**：每个设备都会记录独立的练习进度

## 未来扩展

- 可以添加练习历史记录查看
- 支持跨设备同步练习进度
- 添加练习目标设置和完成提醒
- 提供更详细的练习分析报告

这个功能大大提升了用户体验，确保用户的每一次练习都能被记录和利用，不会因为各种原因导致练习进度丢失。
