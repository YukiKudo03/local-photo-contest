# frozen_string_literal: true

module TutorialsHelper
  # チュートリアルターゲット用のdata属性を生成
  def tutorial_target(name)
    { "data-tutorial": name }
  end

  # チュートリアルコンテナをレンダリング
  def render_tutorial_container(tutorial_type: nil, auto_start: false)
    return unless current_user&.tutorial_enabled?

    render partial: "tutorials/tutorial_container",
           locals: {
             tutorial_type: tutorial_type || current_user.onboarding_tutorial_type,
             auto_start: auto_start
           }
  end

  # ウェルカムモーダルをレンダリング（初回オンボーディング用）
  def render_welcome_modal
    return unless current_user&.should_show_onboarding?

    render partial: "tutorials/welcome_modal"
  end

  # ヘルプボタンをレンダリング
  def render_tutorial_help_button(tutorial_type)
    return unless current_user&.tutorial_enabled?

    render partial: "tutorials/help_button",
           locals: { tutorial_type: tutorial_type }
  end

  # チュートリアル進捗を取得
  def tutorial_progress_for(tutorial_type)
    current_user&.tutorial_progress_for(tutorial_type)
  end

  # チュートリアルが完了しているか
  def tutorial_completed?(tutorial_type)
    current_user&.tutorial_completed?(tutorial_type)
  end

  # チュートリアルを表示すべきか
  def should_show_tutorial?(tutorial_type)
    current_user&.should_show_tutorial?(tutorial_type)
  end

  # チュートリアルステップ数を取得
  def tutorial_step_count(tutorial_type)
    TutorialStep.for_type(tutorial_type).count
  end

  # チュートリアル進捗率を取得
  def tutorial_progress_percentage(tutorial_type)
    progress = current_user&.tutorial_progress_for(tutorial_type)
    progress&.progress_percentage || 0
  end

  # チュートリアルステータスラベルを取得
  def tutorial_status_label(tutorial_type)
    progress = current_user&.tutorial_progress_for(tutorial_type)
    progress&.status_label || "未開始"
  end

  # チュートリアルステータスに応じたCSSクラスを返す
  def tutorial_status_class(tutorial_type)
    progress = current_user&.tutorial_progress_for(tutorial_type)
    case progress&.status
    when :completed
      "text-green-600 bg-green-100"
    when :in_progress
      "text-blue-600 bg-blue-100"
    when :skipped
      "text-gray-500 bg-gray-100"
    else
      "text-gray-400 bg-gray-50"
    end
  end

  # チュートリアルタイプの表示名を取得
  def tutorial_type_label(tutorial_type)
    labels = {
      "participant_onboarding" => "参加者向けガイド",
      "organizer_onboarding" => "運営者向けガイド",
      "admin_onboarding" => "管理者向けガイド",
      "judge_onboarding" => "審査員向けガイド",
      "contest_creation" => "コンテスト作成",
      "area_management" => "エリア管理",
      "judge_invitation" => "審査員招待",
      "moderation" => "モデレーション",
      "statistics" => "統計・分析",
      "photo_submission" => "写真投稿",
      "voting" => "投票"
    }
    labels[tutorial_type] || tutorial_type
  end

  # コンテキストヘルプを表示
  # @param title [String] ヘルプタイトル
  # @param content [String] ヘルプ内容
  # @param options [Hash] オプション
  # @option options [String] :position ツールチップ位置 (top, bottom, left, right)
  # @option options [Boolean] :icon ヘルプアイコンを表示するか (default: true)
  # @option options [String] :class 追加のCSSクラス
  def context_help(title:, content:, **options)
    return "" unless context_help_enabled?

    position = options.fetch(:position, "top")
    show_icon = options.fetch(:icon, true)
    css_class = options[:class]

    data_attrs = {
      controller: "context-help",
      "context-help-title-value": title,
      "context-help-content-value": content,
      "context-help-position-value": position
    }

    if show_icon
      tag.span(
        class: [ "context-help-trigger", css_class ].compact.join(" "),
        **data_attrs,
        aria: { label: "ヘルプ: #{title}" },
        tabindex: 0
      ) { "?" }
    else
      data_attrs
    end
  end

  # コンテキストヘルプが有効かどうか
  def context_help_enabled?
    return true unless current_user

    settings = current_user.tutorial_settings || {}
    settings.fetch("show_context_help", true)
  end

  # コンテキストヘルプ用のメタタグを出力
  def context_help_meta_tag
    return "" unless current_user

    settings = current_user.tutorial_settings || {}
    tag.meta(name: "tutorial-settings", content: settings.to_json)
  end

  # 機能キーのラベルを取得
  def feature_label(feature_key)
    labels = {
      "submit_entry" => "写真投稿",
      "comment" => "コメント",
      "share" => "シェア",
      "create_contest_custom" => "カスタムコンテスト作成",
      "area_management" => "エリア管理",
      "judge_invitation" => "審査員招待",
      "evaluation_criteria" => "評価基準設定",
      "statistics" => "統計・分析",
      "result_announcement" => "結果発表",
      "advanced_moderation" => "高度なモデレーション",
      "system_settings" => "システム設定"
    }
    labels[feature_key] || feature_key
  end

  # 動画チュートリアルボタンを表示
  # @param url [String] 動画URL（YouTube, Vimeoなど）
  # @param title [String] 動画タイトル
  # @param options [Hash] オプション
  # @option options [String] :class 追加のCSSクラス
  # @option options [String] :button_text ボタンテキスト
  def video_tutorial_button(url:, title:, **options)
    return "" if url.blank?

    button_text = options.fetch(:button_text, "動画で見る")
    css_class = options[:class]

    tag.button(
      type: "button",
      class: [
        "inline-flex items-center gap-2 px-3 py-2 text-sm font-medium",
        "text-indigo-600 bg-indigo-50 rounded-lg hover:bg-indigo-100 transition-colors",
        css_class
      ].compact.join(" "),
      data: {
        controller: "video-tutorial",
        "video-tutorial-url-value": url,
        "video-tutorial-title-value": title,
        action: "click->video-tutorial#open"
      }
    ) do
      safe_join([
        tag.svg(
          class: "w-4 h-4",
          fill: "currentColor",
          viewBox: "0 0 20 20"
        ) do
          tag.path(
            fill_rule: "evenodd",
            d: "M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z",
            clip_rule: "evenodd"
          )
        end,
        button_text
      ])
    end
  end
end
