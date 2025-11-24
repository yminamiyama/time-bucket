# Feature Specification: Time Bucket App

**Created**: 2025-11-17  
**Status**: Draft  
**Input**: User description: "docs/time-bucket-app.input.md"  
**Language Requirement**: 本仕様書は全編日本語で記載する。

## User Scenarios & Testing *(mandatory)*

### User Story 1 - バケットとやりたいことを年代別に整理する (Priority: P1)

20〜60代のユーザーとして、人生を5〜10年単位のタイムバケットに分割し、各バケットに「やりたいこと（BucketItem）」を登録したい。年代に合ったタイミングで行動計画を作成し、後悔の少ない人生設計につなげる。

**Why this priority**: タイムバケット思想のコア体験であり、アプリの存在価値を直接生むMVP領域のため。

**Independent Test**: 新規ユーザーがアカウント作成直後に3つのバケットを作成し、カテゴリ・難易度・リスクを含むBucketItemを5件追加できれば完了。

**Acceptance Scenarios**:

1. **Given** 新規ユーザー, **When** 10年刻みでバケットを追加しstart_age/end_ageを保存すると, **Then** 各バケットがリストに表示され編集可能になる。
2. **Given** 既存のバケット, **When** BucketItemをカテゴリ・難易度・リスク・コスト・予定時期付きで登録すると, **Then** バケット内のアイテム一覧と計画ボードに直ちに反映される。
3. **Given** 登録済みBucketItem, **When** ステータスをplanned/in_progress/doneへ更新すると, **Then** タイムライン上の状態と統計値が更新され履歴が残る。

---

### User Story 2 - タイムライン/ダッシュボードで偏りと優先度を把握する (Priority: P2)

人生全体を俯瞰したいユーザーとして、年代別の密度、カテゴリの偏り、今優先すべき項目を可視化するダッシュボードを見たい。視覚的なフィードバックで行動判断をサポートする。

**Why this priority**: タイムバケット手法の価値（適切なタイミングとバランス）を顧客に伝え、継続利用と有料化に直結する。

**Independent Test**: BucketItemが異なる年代・カテゴリで20件存在するとき、ダッシュボードが密度ヒートマップ・カテゴリ比率・今すぐやるべき項目リストを描画し、CSVエクスポートせずとも判断できれば完了。

**Acceptance Scenarios**:

1. **Given** 10年以上分のバケットデータ, **When** ダッシュボードを開くと, **Then** 各バケットの件数/リスク/コスト合計とカテゴリ割合が図式化される。
2. **Given** 各BucketItemにtarget_yearが設定済み, **When** 年齢曲線ロジックが今後5年以内に実行すべき項目を抽出すると, **Then** 「今すぐやるべき」リストに並び優先度根拠（体力ピーク等）が表示される。
3. **Given** 完了済みバケット, **When** ダッシュボードでフィルタを適用すると, **Then** 経験済みのBucketItemが棚卸しビューに切り替わり達成率がパーセントで表示される。

---

### User Story 3 - AIインサイトによる推奨（将来スコープ） (Priority: P3 / Deferred)

将来的には、Die With Zero的視点からAIが推奨や警告を提示する体験を追加したい。ただし現MVPではAI推論や外部連携を行わず、データ構造とUIプレースホルダーの検討に留める。

**Why this priority**: 差別化要素だが、コスト/実装負荷が高いため次フェーズで扱う。

**Independent Test**: 現フェーズでは適用外。Planned段階で要件と評価方法を定義する。

**Acceptance Scenarios**: Deferred（将来の設計ドキュメントで定義）

### Edge Cases

- バケット期間が重複した場合：start_age/end_ageが交差する際はAPIが422を返し、既存バケットを提示する。
- target_yearがバケット期間外の場合：自動で近い年齢にスナップし、ユーザーに確認ダイアログを表示する。
- ステータスがdoneだがtarget_yearが未来のケース：完了日時を必須入力にして整合性が取れない場合は完了不可。
- Google OAuthが失敗した場合：匿名利用は許可せず、ログインリトライ導線を出す。
- バケット内BucketItemがゼロ件のとき：ダッシュボードは「空」状態メッセージと推奨テンプレートを表示し、グラフは0件扱い。
- 過剰な項目数（例：1000件）でも応答がタイムアウトしないよう、サーバー側でページング＋キャッシュを適用する。
- ユーザーが5年刻みテンプレートから10年刻みに切り替えた場合：既存バケットを再生成し、BucketItemは最寄りの新バケットとtarget_yearの整合を確認して再割当案を提示する。

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: ユーザーはGoogle OAuthを用いたSSOで安全にサインアップ/ログインできなければならない（MVPではGoogleのみ）。
- **FR-002**: ユーザーは20歳から最大100歳までの範囲で『5年刻み』または『10年刻み』のテンプレートを選択し、TimeBucketを自動生成できる。テンプレート以外の刻みは許可しない。
- **FR-003**: 自動生成されたTimeBucketはユーザーが後から編集/削除/追加できるが、期間重複チェックはサーバー側で行う。
- **FR-004**: BucketItemにはタイトル、詳細、カテゴリ、難易度、リスク、想定コスト、ステータス、target_year、タグ、メモ、価値/意味を登録できる。
- **FR-005**: BucketItemはstart_age/end_ageと整合するtarget_yearを必須とし、バリデーションに失敗した場合は理由を返す。
- **FR-006**: ダッシュボードはバケット密度、カテゴリ偏り、今すぐやるべき項目、完了済み棚卸しをビジュアル化する。
- **FR-007**: 「今すぐやるべき」抽出はユーザーが登録した生年月日（現在年齢）とtarget_yearのみを用いる。近接（±5年）または超過したBucketItemをハイライトし、理由テキストを付与する。
- **FR-008**: 年齢情報はプロフィールの必須項目であり、変更時は「今すぐやるべき」リストと関連統計を即座に再計算する。
- **FR-009**: 各操作はSlack/メール等に通知できるオプションを提供し、通知設定はユーザーごとに保持する。
- **FR-010**: ダッシュボードは完了済みデータの棚卸しビューを提供し、カテゴリ別達成率と累積コストを表示する。
- **FR-011**: システムは価値観マップやDie With Zeroの指針と矛盾するCRUDライクな体験（単なるタスクリスト化）を防ぐため、BucketItem作成時に「価値/意味」入力を強制する。
- **FR-012**: AIインサイト用のAPIや外部推論は本スコープでは実装しない。将来フェーズで再評価する旨を仕様とUI文言に明記する。

### Key Entities *(include if feature involves data)*

- **User**: Google OAuth経由で認証される個人。プロフィールに生年月日（現在年齢算出用）、価値観タグ、通知設定を保持し、複数のTimeBucketを所有する。
- **TimeBucket**: start_age、end_age、label、説明を持つ年代区間。テンプレート（5年刻み or 10年刻み）から自動生成され、Userに属し、複数のBucketItemを内包する。同一ユーザー内では期間重複禁止。
- **BucketItem**: タイトル、カテゴリ、難易度、リスクレベル、想定コスト、ステータス、target_year、メモ、価値観タグを保持。TimeBucketに属し、「今すぐやるべき」判定やダッシュボード計算の対象になる。
- **InsightPlaceholder**: 将来のAI拡張で利用するメタ情報を保持（type, reason, target_item_id, created_at）。MVPではユーザーUIに表示せず、将来データ移行用として保存のみ行う。
- **NotificationPreference**: User単位で作成され、どのイベント（期限警告、完了棚卸し、テンプレート再生成）をどのチャネルへ送るか定義する。

## Interface Contracts *(mandatory)*

- **API**: `POST /api/time-buckets/templates`
  - **Input Validation**: `granularity`は`5y`または`10y`のみ。ユーザー生年月日は必須。生成範囲は20歳〜100歳で固定。
  - **Output & Logging**: JSONで生成バケット配列を返し、`template_id`と`bucket_count`を構造化ログに記録。
  - **Backward Compatibility**: 新しい刻みを追加する際は`granularity`値を拡張し、既存値の意味を維持する。

- **API**: `POST /api/time-buckets`
  - **Input Validation**: `label`必須、`start_age < end_age`、既存バケットと重複禁止。違反時は422 + `error_code`。
  - **Output & Logging**: JSONで`id`, `label`, `start_age`, `end_age`を返し、`bucket_id`, `user_id`, `action=create`をログ出力。
  - **Backward Compatibility**: バケット期間ルールが変わる可能性があるため、APIバージョン`v1`プレフィックスを維持する。

- **API**: `POST /api/bucket-items`
  - **Input Validation**: target_yearが関連TimeBucket内であること、`category`は定義済みリスト、`status`はplanned/in_progress/doneのみ。
  - **Output & Logging**: JSONでBucketItem全体を返し、監査ログに`risk_level`と`cost_estimate`を記録。
  - **Backward Compatibility**: 将来ステータス追加時はEnum拡張をversioned schemaで提供。

- **API**: `GET /api/dashboard/summary`
  - **Input Validation**: 認証済みユーザーのみ、クエリに`view=overview|accomplished`。不正値は400。
  - **Output & Logging**: JSONで密度ヒートマップ、カテゴリ比率、棚卸し統計を返し、Render Metrics + Logtail/Axiomにレスポンス時間と集計コストを記録。
  - **Backward Compatibility**: レスポンスに新カードを追加する際は`extras`フィールドにネストして既存キーを壊さない。

- **API**: `GET /api/dashboard/actions-now`
  - **Input Validation**: 認証済みユーザーのみ。プロフィールに生年月日が未登録の場合は400。
  - **Output & Logging**: target_yearとの差が±5年以内または超過したBucketItemを理由（近接/期限超過）付きで返し、抽出時間をメトリクスに記録。
  - **Backward Compatibility**: 閾値を変更する際はレスポンスに`threshold_years`を含め、クライアントが表示を調整できるようにする。

- **API**: `POST /api/notifications/test`
  - **Input Validation**: 通知チャネル（email/slack/webhook）のいずれか必須。Rate limit: 1分あたり1回。
  - **Output & Logging**: 成功/失敗ステータスを返し、`channel`, `latency_ms`をログ出力。
  - **Backward Compatibility**: 新チャネル追加時はレスポンス`channels_supported`に含める。

- **Placeholder**: `POST /api/insights/generate`
  - **Status**: v1では未実装。エンドポイントは予約済みだが 501 を返し、将来フェーズでAI推論を追加する。
  - **Expectation**: 仕様書に非対応である旨を明記し、クライアントはUI上で「近日対応予定」表示を行う。

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 新規ユーザーの80%が初回セッション内に最低3つのBucketItemを登録できる（計測: フロントイベント + サーバー保存ログ）。
- **SC-002**: ダッシュボードAPIのp95応答時間は200ms以下、90%のリクエストでキャッシュヒット率70%以上（Render Metrics + Logtail/Axiomで計測）。
- **SC-003**: 「今すぐやるべき」リストを閲覧したユーザーの60%以上が7日以内に1件以上ステータスを更新する（PostHogイベント計測）。
- **SC-004**: 5年/10年テンプレート生成後の初回30日間で、ユーザーの70%以上が「今すぐやるべき」ビューを2回以上閲覧する（PostHog/Logtailイベントで計測）。
