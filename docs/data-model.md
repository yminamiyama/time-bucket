# Data Model — Time Bucket App

**作成日**: 2025-11-17  
**入力**: `spec.md`, `research.md`

## Entity Overview

| Entity | 説明 | 主な関係 |
|--------|------|----------|
| User | 認証済みユーザー。生年月日・価値観タグ・通知設定を保持。 | 1:N TimeBucket, 1:1 NotificationPreference |
| TimeBucket | 5年/10年刻みの年代スロット。 | N:1 User, 1:N BucketItem |
| BucketItem | やりたいこと。カテゴリ/リスク/target_yearなどを持つ。 | N:1 TimeBucket |
| InsightPlaceholder | 将来のAIインサイト結果を保存する枠。MVPでは表示しない。 | N:1 BucketItem |
| NotificationPreference | 通知チャネル設定。 | 1:1 User |

## User
- `id (UUID)`
- `email (citext, unique)`
- `encrypted_password`
- `provider` / `uid` (OAuth連携用)
- `birthdate (date)` — 必須、現在年齢算出
- `values_tags (jsonb)` — 価値観マップ
- `timezone (string)` — 通知の送信時刻
- `created_at`, `updated_at`

Validations:
- email一意 & フォーマット
- birthdateは(現在年-100)〜(現在年-20)（例: 1925-01-01〜2005-12-31）

## TimeBucket
- `id (UUID)`
- `user_id (fk Users)`
- `label (string)` — 例: "20-24"
- `start_age (integer)`
- `end_age (integer)`
- `granularity (enum: 5y | 10y)`
- `description (text)`
- `position (integer)` — 表示順
- `created_at`, `updated_at`

Business Rules:
- start_age >= 20, end_age <= 100
- granularityはユーザー選択値に一致
- 重複検知: `(start_age, end_age)` が被る場合は、DBの排他制約（PostgreSQLの exclusion constraint）またはアプリケーションレベルのバリデーションで防ぐこと

## BucketItem
- `id (UUID)`
- `time_bucket_id (fk TimeBuckets)`
- `title (string, required)`
- `description (text)`
- `category (enum: travel | career | family | finance | health | learning | other)`
- `difficulty (enum: low | medium | high)`
- `risk_level (enum: low | medium | high)`
- `cost_estimate (integer)` — 通貨: JPY, 単位1,000円
- `status (enum: planned | in_progress | done)`
- `target_year (integer)` — 実際の西暦
- `value_statement (text)` — 価値/意味
- `tags (text[])`
- `notes (jsonb)` — 自由入力
- `completed_at (timestamp)`
- `created_at`, `updated_at`

Constraints:
- target_year は「ユーザーの生年（birthdateの年部分） + TimeBucketの start_age/end_age」で算出される範囲内
- statusが`done`の場合、`completed_at`必須

## InsightPlaceholder
- `id (UUID)`
- `bucket_item_id (fk BucketItems)`
- `insight_type (enum: deadline_risk | bias_alert | elderly_safe)`
- `reason (text)`
- `logic_version (integer)`
- `status (enum: deferred | future_release)`
- `created_at`, `updated_at`

## NotificationPreference
- `id (UUID)`
- `user_id (fk Users, unique)`
- `email_enabled (boolean)`
- `slack_webhook_url (string)`
- `digest_time (string)` — HH:MM
- `events (jsonb)` — { "deadline_alert": true, ... }
- `created_at`, `updated_at`

## Relationships Diagram (簡易)

```
User 1---N TimeBucket 1---N BucketItem 1---N InsightPlaceholder
  |
  +---1 NotificationPreference
```
