# 学生项目进展管理系统 MVP

基于资料包要求实现的可运行 MVP，技术栈为：
- Next.js + TypeScript
- Tailwind CSS
- shadcn/ui（手动组件落地）
- Supabase（Auth + PostgreSQL + Storage）

## 1. 目录结构

```text
/app
  /(auth)/login
  /dashboard
  /student
  /projects
  /tasks
  /updates/new
  /teacher
  /api
/components
/lib
/types
/prompts
/supabase
/public
```

## 2. 已实现能力（MVP）

- 登录与角色区分：`student` / `teacher`
- 学生端：
  - 我的项目
  - 我的任务
  - 发布进展更新（今日推进、已完成内容、当前卡点、下一步、完成度）
  - 附件上传
- 教师端：
  - 项目总览
  - 风险项目识别
  - 最近更新时间
  - 总体进度
- 项目详情页：
  - 基本信息
  - 任务列表（支持状态更新）
  - 更新记录
  - 附件列表
- AI 模块：
  - 已接入 OpenAI Responses API（周总结）
  - `/api/ai/weekly-summary` 根据最近 7 天 updates 生成并写入 `ai_summaries`
  - 教师端 `AI 周报汇总` 页面支持按项目生成与查看周报
  - `/api/ai/project-summary` 与 `/api/ai/risk-analysis` 保留接口骨架

## 3. 本地运行

### 3.1 安装依赖

```bash
npm install
```

### 3.2 配置环境变量

复制 `.env.example` 为 `.env.local` 并填写：

```env
NEXT_PUBLIC_SUPABASE_URL=...
NEXT_PUBLIC_SUPABASE_ANON_KEY=...
NEXT_PUBLIC_APP_NAME=Student Project Tracker
OPENAI_API_KEY=...
OPENAI_MODEL=gpt-4.1-mini
```

### 3.3 初始化数据库

1. 打开 Supabase SQL Editor
2. 执行 `supabase/schema.sql`
3. 在 Supabase Auth 中创建测试账号
4. 在 `public.users` 中为账号写入角色（`student` 或 `teacher`）

### 3.4 启动开发环境

```bash
npm run dev
```

访问：`http://localhost:3000`

## 4. 关键 API 路由

- 认证
  - `POST /api/auth/login`
  - `POST /api/auth/logout`
  - `GET /api/auth/me`
- 项目
  - `GET /api/projects`
  - `POST /api/projects`
  - `GET /api/projects/:id`
  - `PATCH /api/projects/:id`
  - `DELETE /api/projects/:id`
- 任务
  - `GET /api/projects/:id/tasks`
  - `POST /api/projects/:id/tasks`
  - `PATCH /api/tasks/:id`
  - `DELETE /api/tasks/:id`
- 更新
  - `GET /api/projects/:id/updates`
  - `POST /api/projects/:id/updates`
- 附件
  - `GET /api/updates/:id/attachments`
- AI
  - `POST /api/ai/project-summary`
  - `GET /api/ai/weekly-summary?projectId=:id`
  - `POST /api/ai/weekly-summary`
  - `POST /api/ai/risk-analysis`

## 5. 风险判定规则（当前）

- 超过 7 天未更新 -> 中风险
- 存在已延期任务 -> 中风险
- 同时满足以上两条 -> 高风险

## 6. 下一步（Sprint 3）

- 将 `project-summary` 与 `risk-analysis` 接口切换到真实 OpenAI 调用
- 增加 AI 总结历史筛选（按时间区间、按项目成员）
