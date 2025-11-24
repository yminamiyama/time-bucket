# Time Bucket App — Portfolio Narrative

**目的**: このドキュメントは、アプリ開発の背景・狙い・設計方針を整理し、プロダクトの価値や自身の意思決定プロセスをわかりやすく伝えるためのサマリです。SpecKitで作成した仕様書（spec/plan/research 等）を凝縮し、学び・改善・工夫点をストーリーとしてまとめています。

---

## 1. このアプリを作った理由
- 『Die With Zero』で紹介される Time Bucket メソッドに強く共感し、「やりたいことを年齢軸で管理する」体験を自分の解釈でプロダクト化したかった。

- 般的なバケットリストは「時期」という概念が弱く、結果としてタスク管理アプリ化してしまう課題を感じていた。

- CRUDに留まらないドメイン設計・UX設計・軽量インフラ構築を一体で行う題材として適しており、個人開発のテーマとして選定した。

## 2. 解決したい課題
| 課題 | 対応機能 |
|------|----------|
| 年齢に応じた優先度が可視化されず、行動が後回しになる | 20〜100歳を5年/10年刻みで管理し、`Actions Now` リストで期限間近/超過をハイライト |
| バケットの偏りに気付きにくい | ダッシュボードでカテゴリ偏り・密度・棚卸し統計を可視化 |
| “やりたいこと” がただのタスクになる | BucketItem作成時に価値/意味の入力を必須化し、CRUD化を抑止 |
| 大げさなインフラはコストに合わない | Render + Vercel + Upstash構成で少額運用を実現 |

## 3. 進め方（プロセス）
1. **Specification (spec.md)**: ユーザーストーリー3本・機能要件・計測指標を日本語で定義。AIインサイトは将来スコープとしてDeferred扱い。
2. **Research (research.md)**: Render vs Fly、Resend vs SES、Logtail/PostHogなどの比較結果をDecision/Rationale形式で記録。
3. **Plan (plan.md)**: フェーズ分解（Foundation → Story 1 → Story 2 → Polish）、Fail-firstテスト、Telemetry方針を明文化。
4. **Data Model / Contracts / Quickstart**: 仕様を支えるモデル設計、OpenAPIライクな契約、ローカル~本番デプロイ手順を整備。
5. **Implementation**: `/speckit.tasks` でタスク化 → Fail-firstテスト（Contract → RSpec → Playwright）でゲートを設け、機能ごとに小さくコミット。

## 4. 技術スタック & 選定理由
| レイヤー | 選定 | 理由 |
|----------|------|------|
| Backend | Ruby 3.3 + Rails 8 (API) | ドメインモデリングが速い、個人でも生産性が高い |
| Frontend | Next.js 15 (App Router) + TypeScript 5 + TailwindCSS + shadcn/ui | UI/UXを素早く構築し、Vercelにそのまま載せられる |
| Dev Environment | Docker Compose (Rails + Next.js + Postgres + Redis) | OS依存なく環境を共有し、`docker compose up`だけで再現できる |
| Auth | Devise + OmniAuth (Google SSO) | AWSに依存せず簡潔にSSOを実現 |
| DB/Caching | Render Managed Postgres + Upstash Redis | 低コストでSSL/Durabilityを担保 |
| Notifications | Resend (メール) + Slack Webhook | 個人用途に最適な価格とシンプルなAPI |
| Observability | Logtail(Axiom) + PostHog + Vercel Analytics | SC-001〜004のメトリクスをすべて可視化可能 |

## 5. 工夫・こだわりポイント
- **Constitution-Driven**: 開発ルールを憲法化し、Spec/Plan/Tasks/Implementation全てで遵守。独自の Constitution 1.1.0 を策定。
- **Fail-First Test Culture**: `tasks-template.md` からテスト必須に変更し、各ストーリーでテストを先に書くプロセスを組み込み。
- **Template & Docs in Japanese**: SpecKitテンプレートを日本語向けに整え、開発者以外でも読みやすい構成にした。
- **Cost-Aware Architecture**: Render/Vercel/Upstash/Resend/PostHog など、無料〜低額プランで継続可能な構成に統一。
- **Dockerized Dev Flow**: Docker ComposeでRails/Next.js/Postgres/Redisを一括起動し、環境差分のないデモ体験を提供。
- **Portfolio Storytelling**: 本ファイルを含め、プロジェクトの背景・選定理由・工夫を“語れる”形で整備。

## 6. 今後の発展
- AIインサイト（Deferred Story）をVertex AIやOpenAI Function Callingで実装し、行動推奨を自然言語で提示。
- モバイル向けUIやPWAを追加し、オフライン閲覧できるようにする。
- コミュニティ共有機能（Bucketテンプレの共有、共同編集）で価値を広げる。

---
