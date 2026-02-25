# Tasks: User Documentation Access

## Phase 1: 基盤構築

- [ ] 1.1 Redcarpet gem の追加とMarkdownヘルパー作成
  - Files: `Gemfile`, `app/helpers/help_helper.rb`
  - Redcarpet と Rouge gem を追加
  - HelpHelper に render_markdown メソッドを実装
  - キャッシュ機構を組み込み
  - Purpose: Markdownパース基盤の構築
  - _Leverage: Railsキャッシュ機構_
  - _Requirements: NFR-001, NFR-002, NFR-005_
  - _Prompt: Implement the task for spec user-documentation-access, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Backend Developer specializing in helper modules | Task: Add redcarpet and rouge gems to Gemfile, create HelpHelper with render_markdown method that parses Markdown files with caching, extract_toc method for generating table of contents from headings, and guide_info method returning metadata for all 4 guides | Restrictions: Use Rails.cache for caching with file mtime as cache key, do not create new models, follow existing helper patterns | Success: bundle install succeeds, render_markdown converts doc/manual/*.md files to HTML with proper formatting, TOC extraction works correctly, unit tests pass | After completing the implementation, set this task to in-progress in tasks.md before starting, use log-implementation tool to record what was built, then mark as complete in tasks.md_

- [ ] 1.2 HelpController の作成
  - Files: `app/controllers/help_controller.rb`, `config/routes.rb`
  - HelpController を作成（index, show アクション）
  - ルーティングを追加（/help, /help/:guide）
  - 認証スキップを設定
  - Purpose: ヘルプページのルーティングとコントローラー
  - _Leverage: app/controllers/application_controller.rb_
  - _Requirements: FR-001, FR-002_
  - _Prompt: Implement the task for spec user-documentation-access, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Controller Developer | Task: Create HelpController with index action (displays all 4 guides as cards) and show action (displays single guide content), add routes for /help and /help/:guide with constraint for valid guide names (participant, organizer, judge, admin), skip authentication | Restrictions: Follow existing controller patterns, use skip_before_action for authenticate_user!, validate guide parameter, return 404 for invalid guides | Success: GET /help returns 200, GET /help/participant returns participant guide content, GET /help/invalid returns 404, no login required | After completing the implementation, set this task to in-progress in tasks.md before starting, use log-implementation tool to record what was built, then mark as complete in tasks.md_

- [ ] 1.3 ヘルプページビューの作成
  - Files: `app/views/help/index.html.erb`, `app/views/help/show.html.erb`, `app/views/help/_toc.html.erb`
  - マニュアル一覧ページ（カード形式）
  - 個別マニュアルページ（目次 + コンテンツ）
  - 目次パーシャル（サイドバー表示）
  - Purpose: ヘルプページのUI実装
  - _Leverage: app/views/layouts/application.html.erb, Tailwind CSS_
  - _Requirements: FR-001, FR-002, NFR-003, NFR-004_
  - _Prompt: Implement the task for spec user-documentation-access, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Frontend Developer with Tailwind CSS expertise | Task: Create index.html.erb with 4 guide cards (2x2 grid on desktop, 1 column on mobile) showing title, description, icon for each guide; create show.html.erb with sticky sidebar TOC on left (desktop) or collapsible accordion (mobile) and markdown content on right; create _toc.html.erb partial for table of contents with anchor links | Restrictions: Use Tailwind CSS classes only, ensure responsive design, follow existing view patterns, use proper heading hierarchy for accessibility | Success: /help shows 4 clickable cards, /help/participant shows guide with working TOC navigation, responsive on all screen sizes | After completing the implementation, set this task to in-progress in tasks.md before starting, use log-implementation tool to record what was built, then mark as complete in tasks.md_

## Phase 2: ナビゲーションリンク追加

- [ ] 2.1 ヘッダーにヘルプリンクを追加
  - File: `app/views/shared/_header.html.erb`
  - ユーザーメニュー（ドロップダウン）内に「ヘルプ」リンクを追加
  - モバイルメニューにも追加
  - Purpose: メインナビゲーションからのアクセス提供
  - _Leverage: 既存のヘッダーパーシャル_
  - _Requirements: FR-003_
  - _Prompt: Implement the task for spec user-documentation-access, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails View Developer | Task: Add "ヘルプ" link to user dropdown menu in _header.html.erb (after プロフィール, before ログアウト), add same link to mobile hamburger menu, use help_path for the link | Restrictions: Do not change existing menu structure, maintain consistent styling with other menu items, ensure link appears for both logged-in and logged-out users | Success: Help link visible in desktop dropdown and mobile menu, clicking navigates to /help | After completing the implementation, set this task to in-progress in tasks.md before starting, use log-implementation tool to record what was built, then mark as complete in tasks.md_

- [ ] 2.2 フッターにヘルプリンクを追加
  - File: `app/views/shared/_footer.html.erb`
  - 「利用ガイド」リンクを追加（既存プレースホルダーを有効化）
  - Purpose: フッターからのアクセス提供
  - _Leverage: 既存のフッターパーシャル_
  - _Requirements: FR-004_
  - _Prompt: Implement the task for spec user-documentation-access, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails View Developer | Task: Update _footer.html.erb to add "利用ガイド" link pointing to help_path, place it in the legal links section alongside 利用規約 and プライバシーポリシー | Restrictions: Follow existing footer styling, do not remove existing placeholder links, maintain responsive layout | Success: Footer shows "利用ガイド" link that navigates to /help | After completing the implementation, set this task to in-progress in tasks.md before starting, use log-implementation tool to record what was built, then mark as complete in tasks.md_

- [ ] 2.3 主催者サイドバーにヘルプセクションを追加
  - File: `app/views/shared/_sidebar.html.erb`
  - 「ヘルプ」セクションをサイドバー最下部に追加
  - 「主催者ガイド」と「全マニュアル」へのリンク
  - Purpose: 主催者向けの便利なアクセス
  - _Leverage: 既存のサイドバーパーシャル_
  - _Requirements: FR-005_
  - _Prompt: Implement the task for spec user-documentation-access, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails View Developer | Task: Add new "ヘルプ" section at the bottom of _sidebar.html.erb with two links: "主催者ガイド" (help_guide_path(:organizer)) and "全マニュアル" (help_path), use question-mark-circle icon for the section | Restrictions: Follow existing sidebar section styling pattern, place after all existing sections, maintain collapsible behavior if applicable | Success: Organizer sidebar shows help section with two working links | After completing the implementation, set this task to in-progress in tasks.md before starting, use log-implementation tool to record what was built, then mark as complete in tasks.md_

- [ ] 2.4 管理画面にヘルプリンクを追加
  - File: `app/views/layouts/admin.html.erb`
  - 管理画面ヘッダーに「管理者ガイド」リンクを追加
  - Purpose: 管理者向けの便利なアクセス
  - _Leverage: 既存の管理画面レイアウト_
  - _Requirements: FR-006_
  - _Prompt: Implement the task for spec user-documentation-access, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails View Developer | Task: Add "管理者ガイド" link to admin layout header navigation in admin.html.erb, place it before the "サイトに戻る" link, use help_guide_path(:admin) | Restrictions: Follow existing admin header styling (dark theme), do not disrupt existing navigation order | Success: Admin header shows "管理者ガイド" link that navigates to /help/admin | After completing the implementation, set this task to in-progress in tasks.md before starting, use log-implementation tool to record what was built, then mark as complete in tasks.md_

- [ ] 2.5 審査員ダッシュボードにヘルプリンクを追加
  - File: `app/views/my/judge_assignments/index.html.erb`
  - ダッシュボード上部に「審査員ガイド」へのリンク/ボタンを追加
  - Purpose: 審査員向けの便利なアクセス
  - _Leverage: 既存の審査員ダッシュボードビュー_
  - _Requirements: FR-007_
  - _Prompt: Implement the task for spec user-documentation-access, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails View Developer | Task: Add "審査員ガイドを見る" link/button to my/judge_assignments/index.html.erb, place it near the page title or in a helpful info box, use help_guide_path(:judge) | Restrictions: Do not disrupt existing page layout, use consistent button/link styling, make it noticeable but not obtrusive | Success: Judge assignments page shows link to judge guide | After completing the implementation, set this task to in-progress in tasks.md before starting, use log-implementation tool to record what was built, then mark as complete in tasks.md_

## Phase 3: i18n と仕上げ

- [ ] 3.1 i18nテキストの追加
  - File: `config/locales/ja.yml`
  - ヘルプページ用のテキストを追加
  - Purpose: 日本語テキストの一元管理
  - _Leverage: 既存のja.yml_
  - _Requirements: NFR-006_
  - _Prompt: Implement the task for spec user-documentation-access, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails i18n Developer | Task: Add Japanese translations to ja.yml for help pages including: page titles, guide names, guide descriptions, navigation labels (ヘルプ, 利用ガイド, 主催者ガイド, 審査員ガイド, 管理者ガイド), back to list link, TOC header | Restrictions: Follow existing ja.yml structure and nesting patterns, use meaningful keys under help namespace | Success: All help page text comes from i18n, no hardcoded Japanese strings in views | After completing the implementation, set this task to in-progress in tasks.md before starting, use log-implementation tool to record what was built, then mark as complete in tasks.md_

- [ ] 3.2 目次のモバイル対応（Stimulusコントローラー）
  - Files: `app/javascript/controllers/toc_controller.js`
  - 目次の折りたたみ機能を実装
  - Purpose: モバイルでの使いやすさ向上
  - _Leverage: 既存のStimulus controllers_
  - _Requirements: NFR-003_
  - _Prompt: Implement the task for spec user-documentation-access, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Stimulus.js Developer | Task: Create toc_controller.js with toggle action for collapsible table of contents on mobile, manage open/closed state, animate smooth expand/collapse, update show.html.erb to use the controller | Restrictions: Follow existing Stimulus controller patterns, use Tailwind classes for animations, ensure accessibility (aria-expanded) | Success: TOC collapses/expands on mobile when clicking toggle button, smooth animation, accessible | After completing the implementation, set this task to in-progress in tasks.md before starting, use log-implementation tool to record what was built, then mark as complete in tasks.md_

## Phase 4: テスト

- [ ] 4.1 ヘルパーのユニットテスト
  - File: `spec/helpers/help_helper_spec.rb`
  - render_markdown、extract_toc のテスト
  - Purpose: ヘルパーメソッドの動作保証
  - _Leverage: spec/rails_helper.rb_
  - _Requirements: Testing Strategy_
  - _Prompt: Implement the task for spec user-documentation-access, first run spec-workflow-guide to get the workflow guide then implement the task: Role: RSpec Test Developer | Task: Create help_helper_spec.rb with tests for render_markdown (converts markdown to HTML, handles code blocks, caches results), extract_toc (extracts h2/h3 headings with anchors), guide_info (returns correct metadata for all 4 guides) | Restrictions: Follow existing spec patterns, use proper RSpec syntax, test edge cases (empty file, missing file) | Success: All helper tests pass, good coverage of normal and edge cases | After completing the implementation, set this task to in-progress in tasks.md before starting, use log-implementation tool to record what was built, then mark as complete in tasks.md_

- [ ] 4.2 コントローラーのリクエストテスト
  - File: `spec/requests/help_spec.rb`
  - index, show アクションのテスト
  - Purpose: APIレベルの動作保証
  - _Leverage: spec/rails_helper.rb_
  - _Requirements: Testing Strategy_
  - _Prompt: Implement the task for spec user-documentation-access, first run spec-workflow-guide to get the workflow guide then implement the task: Role: RSpec Request Test Developer | Task: Create help_spec.rb with request tests for GET /help (returns 200, renders index), GET /help/participant (returns 200, contains guide content), GET /help/invalid (returns 404), verify no authentication required for all endpoints | Restrictions: Follow existing request spec patterns, test all 4 valid guide types, verify response content | Success: All request tests pass, 404 handling verified | After completing the implementation, set this task to in-progress in tasks.md before starting, use log-implementation tool to record what was built, then mark as complete in tasks.md_

- [ ] 4.3 システムテスト
  - File: `spec/system/help_spec.rb`
  - ナビゲーション、目次、レスポンシブのテスト
  - Purpose: E2Eでの動作保証
  - _Leverage: spec/system/support/, Capybara_
  - _Requirements: Testing Strategy_
  - _Prompt: Implement the task for spec user-documentation-access, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Capybara System Test Developer | Task: Create help_spec.rb system tests for: navigating from header to help page, clicking guide cards to view guides, TOC anchor links scroll to correct sections, help links appear in organizer sidebar and admin header, mobile TOC toggle works | Restrictions: Follow existing system spec patterns, use proper Capybara matchers, test both desktop and mobile viewports | Success: All system tests pass, user flows verified end-to-end | After completing the implementation, set this task to in-progress in tasks.md before starting, use log-implementation tool to record what was built, then mark as complete in tasks.md_

## Summary

| Phase | Tasks | Purpose |
|-------|-------|---------|
| Phase 1 | 1.1-1.3 | 基盤構築（Gem、Controller、Views） |
| Phase 2 | 2.1-2.5 | ナビゲーションリンク追加 |
| Phase 3 | 3.1-3.2 | i18nとモバイル対応 |
| Phase 4 | 4.1-4.3 | テスト実装 |

**Total Tasks**: 13
**Estimated Files**: 15+
