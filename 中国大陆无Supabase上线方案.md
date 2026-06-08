# 中国大陆无 Supabase 上线方案

如果系统要在中国大陆公司环境上线，并且不使用 Supabase，推荐把当前架构改成下面这一套。

## 1. 结论

可以不用 Supabase，但不是只改 `.env.local`。

当前 Supabase 承担了这些职责：

```text
用户注册 / 登录 / 找回密码
用户 session 识别
PostgreSQL 数据库查询
附件上传和公开访问
部分权限控制
```

不用 Supabase 后，需要替换为：

```text
数据库：阿里云 RDS PostgreSQL / 腾讯云 TencentDB for PostgreSQL / 公司自建 PostgreSQL
认证：Auth.js 或自研账号密码登录
附件：阿里云 OSS / 腾讯云 COS / 公司内网对象存储
AI：OpenAI 可用则继续；不可用则换成国内大模型接口
部署：公司服务器 + Node.js + Nginx + HTTPS
```

## 2. 推荐大陆部署架构

### 方案 A：阿里云

```text
Next.js 应用：阿里云 ECS / 容器服务 ACK
数据库：阿里云 RDS PostgreSQL
附件存储：阿里云 OSS
域名和 HTTPS：阿里云域名 + SSL 证书 + Nginx
AI：OpenAI 或通义千问 DashScope
```

### 方案 B：腾讯云

```text
Next.js 应用：腾讯云 CVM / TKE
数据库：TencentDB for PostgreSQL
附件存储：腾讯云 COS
域名和 HTTPS：腾讯云域名 + SSL 证书 + Nginx
AI：OpenAI 或腾讯混元 / DeepSeek / 智谱等
```

### 方案 C：公司内网私有化

```text
Next.js 应用：公司内网服务器
数据库：自建 PostgreSQL
附件存储：服务器本地磁盘或 MinIO
域名：公司内网 DNS 或固定 IP
AI：公司允许访问的模型服务
```

如果公司只是内部试用，方案 C 最省事。如果要正式对外访问，方案 A 或 B 更稳。

## 3. 需要改造的代码模块

### 3.1 数据库访问层

当前代码大量使用：

```ts
createSupabaseServerClient()
supabase.from("projects").select(...)
supabase.from("tasks").insert(...)
```

建议替换为 Prisma 或 Drizzle。

推荐优先级：

```text
Prisma：适合学生继续维护，类型清晰，资料多
Drizzle：更轻量，但对初学者略难
node-postgres pg：最直接，但 SQL 和类型维护成本更高
```

建议采用：

```text
Prisma + PostgreSQL
```

需要新增：

```text
prisma/schema.prisma
lib/db.ts
lib/repositories/*
```

然后把 `lib/services/*` 和 `app/api/*` 里的 Supabase 查询逐步换成 Prisma 查询。

### 3.2 用户认证

当前 Supabase Auth 要替换掉。

推荐两种方式：

```text
Auth.js：成熟，适合 Next.js
自研 session：更可控，适合内网系统
```

如果这个系统只是公司内部用，我建议用自研账号密码登录，原因是逻辑更容易理解：

```text
users 表增加 password_hash 字段
注册时 bcrypt 加密密码
登录时校验密码
通过 httpOnly cookie 保存 session
退出登录时清除 cookie
找回密码改为管理员重置密码，或邮件服务发送重置链接
```

需要新增表：

```sql
user_sessions
password_reset_tokens
```

或者简单一点，内部系统先做：

```text
管理员重置密码
用户首次登录后修改密码
```

这样比邮件找回密码更适合内网环境。

### 3.3 附件上传

当前代码使用：

```ts
supabase.storage.from("attachments").upload(...)
```

大陆替代：

```text
阿里云 OSS
腾讯云 COS
MinIO
服务器本地磁盘
```

推荐：

```text
正式公司环境：OSS / COS
内网试用：MinIO 或服务器本地磁盘
```

需要新增：

```text
lib/storage/index.ts
lib/storage/aliyun-oss.ts
lib/storage/tencent-cos.ts
```

统一暴露：

```ts
uploadAttachment(file): Promise<{ url: string; path: string }>
```

这样以后换云厂商不用改业务页面。

### 3.4 AI 周报

当前已经有 OpenAI 服务层，可以保留接口结构。

大陆可选：

```text
继续使用 OpenAI：如果公司网络和合规允许
换国内模型：通义千问、腾讯混元、智谱、DeepSeek 等
```

建议把 AI 服务抽象成 Provider：

```text
lib/services/ai/openai.ts
lib/services/ai/qwen.ts
lib/services/ai/deepseek.ts
lib/services/ai/index.ts
```

环境变量：

```env
AI_PROVIDER=qwen
AI_API_KEY=xxxx
AI_MODEL=qwen-plus
```

这样大陆环境不用改页面，只换 AI provider。

## 4. 数据库表结构是否能保留

可以保留大部分表结构：

```text
users
projects
project_members
tasks
updates
attachments
ai_summaries
system_logs
project_change_requests
```

但是 users 表需要增加：

```sql
password_hash text
last_login_at timestamptz
status text default 'active'
```

如果要做 session：

```sql
create table user_sessions (
  id uuid primary key,
  user_id uuid references users(id) on delete cascade,
  token_hash text not null,
  expires_at timestamptz not null,
  created_at timestamptz default now()
);
```

如果要做找回密码：

```sql
create table password_reset_tokens (
  id uuid primary key,
  user_id uuid references users(id) on delete cascade,
  token_hash text not null,
  expires_at timestamptz not null,
  used_at timestamptz,
  created_at timestamptz default now()
);
```

## 5. 工作量评估

如果只是本地/内网跑，不替换 Supabase：

```text
0.5 天：配置环境、部署、测试
```

如果中国大陆正式上线，不使用 Supabase：

```text
2-4 天：替换数据库访问层
1-2 天：替换登录注册 session
0.5-1 天：替换附件上传
0.5-1 天：替换 AI provider
1 天：联调、测试、修 bug
```

比较现实的总工作量：

```text
5-8 个工作日
```

如果要求更严格的权限、安全审计、日志留存、管理员后台、数据备份，时间还要增加。

## 6. 上线合规提醒

如果系统只在公司局域网内部访问，通常比公网简单很多。

如果要公网访问中国大陆服务器，一般需要准备：

```text
域名备案 ICP
公安联网备案
HTTPS 证书
隐私政策
用户数据保护方案
数据库备份方案
日志留存方案
```

如果系统涉及学生个人信息、学校数据、项目成果数据，建议公司内部再确认数据合规要求。

这部分不是代码问题，最好让公司 IT / 法务 / 信息安全负责人一起确认。

## 7. 推荐执行路线

我建议不要一口气全换，按这个路线做最稳：

```text
第一步：先保留现有页面和业务逻辑
第二步：新增 Prisma + PostgreSQL
第三步：把查询服务层从 Supabase 改成 Prisma
第四步：替换 Supabase Auth 为自研 session
第五步：替换 Supabase Storage 为 OSS/COS/MinIO
第六步：AI 服务改成 provider 可切换
第七步：删除 Supabase SDK 和环境变量
第八步：部署到公司服务器做完整验收
```

## 8. 给学生的一句话任务说明

如果你要把任务交给学生，可以这样说：

```text
请把当前 Next.js 项目从 Supabase 架构迁移到中国大陆可部署架构：PostgreSQL + Prisma + 自研账号 session + OSS/COS 文件存储 + 可切换 AI Provider。要求保留现有页面功能和业务逻辑，完成后能在公司服务器通过 npm run build 和 npm run start 正常运行。
```

## 9. 我建议的最终技术栈

```text
Next.js + TypeScript + Tailwind CSS + shadcn/ui
PostgreSQL
Prisma
bcryptjs
httpOnly cookie session
阿里云 OSS 或腾讯云 COS
OpenAI / 通义千问 / DeepSeek 可切换 AI Provider
Nginx + HTTPS
PM2 或 Docker
```

这个方案对中国大陆上线更稳，也方便公司后续维护。
