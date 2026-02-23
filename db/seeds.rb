# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Creating Terms of Service..."

terms_content = <<~TERMS
  Local Photo Contest 利用規約

  第1条（目的）
  本規約は、Local Photo Contest（以下「本サービス」）の利用条件を定めるものです。

  第2条（利用資格）
  本サービスを利用するには、本規約に同意する必要があります。

  第3条（禁止事項）
  以下の行為を禁止します。
  - 法令に違反する行為
  - 他者の権利を侵害する行為
  - 公序良俗に反する行為
  - 本サービスの運営を妨害する行為

  第4条（著作権）
  投稿された写真の著作権は、投稿者に帰属します。ただし、本サービスでの公開・展示について許諾したものとみなします。

  第5条（免責事項）
  本サービスの利用により生じた損害について、運営者は責任を負いません。

  第6条（規約の変更）
  本規約は、必要に応じて変更されることがあります。変更後の規約は、本サービス上に掲載された時点で効力を生じます。

  制定日: 2024年1月1日
TERMS

TermsOfService.find_or_create_by!(version: "1.0") do |terms|
  terms.content = terms_content
  terms.published_at = Time.current
end

puts "Terms of Service created."

# Create test organizer in development
if Rails.env.development?
  puts "Creating test organizer..."

  organizer = User.find_or_initialize_by(email: "organizer@example.com")
  if organizer.new_record?
    organizer.password = "password123"
    organizer.password_confirmation = "password123"
    organizer.role = :organizer
    organizer.skip_confirmation!
    organizer.save!
    puts "Test organizer created: organizer@example.com / password123"
  else
    puts "Test organizer already exists."
  end

  # Create test admin
  admin = User.find_or_initialize_by(email: "admin@example.com")
  if admin.new_record?
    admin.password = "password123"
    admin.password_confirmation = "password123"
    admin.role = :admin
    admin.skip_confirmation!
    admin.save!
    puts "Test admin created: admin@example.com / password123"
  else
    puts "Test admin already exists."
  end
end

# Create default categories
puts "Creating default categories..."

default_categories = [
  { name: "風景", description: "自然風景、都市風景などの写真" },
  { name: "人物", description: "ポートレート、スナップなどの人物写真" },
  { name: "動物", description: "ペット、野生動物などの動物写真" },
  { name: "花・植物", description: "花、木、植物などの写真" },
  { name: "建築", description: "建物、構造物などの写真" },
  { name: "食べ物", description: "料理、スイーツなどの写真" },
  { name: "スポーツ", description: "スポーツ、アクティビティの写真" },
  { name: "祭り・イベント", description: "地域の祭り、イベントの写真" },
  { name: "その他", description: "上記に当てはまらないカテゴリ" }
]

default_categories.each_with_index do |attrs, index|
  Category.find_or_create_by!(name: attrs[:name]) do |category|
    category.description = attrs[:description]
    category.position = index + 1
  end
end

puts "#{Category.count} categories created."

# Create default areas (Japanese regions)
puts "Creating default areas..."

# エリア作成用のユーザーを取得（開発環境ではorganizer、本番では最初のadmin）
area_owner = if Rails.env.development?
               User.find_by(email: "organizer@example.com")
             else
               User.find_by(role: :admin) || User.first
             end

default_areas = [
  "北海道",
  "東北",
  "関東",
  "中部",
  "近畿",
  "中国",
  "四国",
  "九州・沖縄",
  "その他"
]

if area_owner
  default_areas.each_with_index do |name, index|
    Area.find_or_create_by!(name: name, user: area_owner) do |area|
      area.position = index + 1
    end
  end
else
  puts "Warning: No user found for area creation. Skipping areas."
end

puts "#{Area.count} areas created."

# Load tutorial steps (v2 - Sakurai philosophy based)
load Rails.root.join("db/seeds/tutorial_steps_v2.rb")

puts "Seed completed!"
