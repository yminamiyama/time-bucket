# Quickstart — Time Bucket App

**対象**: 開発者がローカル環境を最短で立ち上げ、テストを実行するための手順  
**前提**: macOS or Linux, Docker Desktop, Node 20, pnpm, Ruby 3.3 (via asdfなど)

---

## 1. リポジトリ初期化
```bash
git clone <repo>
cd time-bucket
asdf install  # .tool-versions に合わせる
pnpm install --store-dir .pnpm-store || pnpm install
bundle install || (echo "Bundler 2.5.22 が必要です" && exit 1)
```

### Docker Compose を利用する場合
```bash
cp .env.example .env
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env
docker compose up --build
# backend: http://localhost:4000, frontend: http://localhost:3000
```

Dockerを使わない場合は従来通りローカルにRuby/Nodeをインストールし、以下の手順を続行する。pnpmストア警告が出た場合は `pnpm install --store-dir .pnpm-store` を利用する。

## 2. 環境変数
```bash
cp .env.example .env.local
cp backend/.env.example backend/.env.local
cp frontend/.env.example frontend/.env.local
```
設定必須項目:
- `POSTGRES_URL` / `REDIS_URL`
- `GOOGLE_OAUTH_CLIENT_ID`, `GOOGLE_OAUTH_CLIENT_SECRET`
- `RESEND_API_KEY`
- `SLACK_WEBHOOK_URL`（任意）
- `POSTHOG_API_KEY`, `LOGTAIL_SOURCE_TOKEN`

## 3. インフラ依存サービス
```bash
docker compose up -d postgres redis localstack
RAILS_ENV=development bundle exec rails db:setup
```

## 4. バックエンド起動
```bash
cd backend
bin/dev # or ./bin/rails server -p 4000
```
主要エンドポイント: `http://localhost:4000/api/v1`

## 5. フロントエンド起動
```bash
cd frontend
pnpm dev --port 3000
```
Next.js App Router が `http://localhost:3000` で起動。

## 6. テスト
- **RSpec**（fail-first前提）
  ```bash
  cd backend
  bundle exec rspec spec/models spec/requests
  ```
- **Contract tests**
  ```bash
  make contract-test  # openapi-validator + dredd
  ```
- **Frontend**
  ```bash
  cd frontend
  pnpm test          # Jest
  pnpm test:e2e      # Playwright
  ```

## 7. 観測
- `overmind start` でRails, Next.js, Tailwind, workerを同時起動。
- ローカルのCloudWatch代替として`docker compose up tempo loki grafana`を用意（任意）。

## 8. デプロイ概略
1. GitHub ActionsでLint/Tests/Playwrightを実行。
2. 成功後、DockerイメージをECRにpush。
3. Terraform CDKスタックを`infrastructure/cdk/bin/deploy`で反映。
4. Next.jsはVercelに自動デプロイ。環境変数はVercel Secrets + AWS Secrets Managerで管理。
