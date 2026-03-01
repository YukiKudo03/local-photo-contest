FactoryBot.define do
  factory :entry do
    association :user, :confirmed
    contest { association :contest, :published }
    title { "サンプル写真" }
    description { "これはサンプルの説明文です。" }
    location { "東京都渋谷区" }
    taken_at { Date.current - 1.week }

    after(:build) do |entry|
      test_image_path = Rails.root.join("spec", "fixtures", "files", "test_photo.jpg")
      if File.exist?(test_image_path)
        entry.photo.attach(
          io: File.open(test_image_path),
          filename: "test_photo.jpg",
          content_type: "image/jpeg"
        )
      else
        # Fallback for when fixture file doesn't exist
        entry.photo.attach(
          io: StringIO.new("fake image data"),
          filename: "test_photo.jpg",
          content_type: "image/jpeg"
        )
      end
    end

    trait :without_photo do
      after(:build) do |entry|
        entry.photo.purge
      end
    end

    trait :without_title do
      title { nil }
    end

    trait :without_description do
      description { nil }
    end

    trait :without_location do
      location { nil }
    end

    trait :without_taken_at do
      taken_at { nil }
    end

    trait :minimal do
      title { nil }
      description { nil }
      location { nil }
      taken_at { nil }
    end

    trait :with_long_title do
      title { "あ" * 100 }
    end

    trait :with_long_location do
      location { "あ" * 255 }
    end

    trait :with_exif do
      exif_data do
        {
          "Make" => "Canon",
          "Model" => "Canon EOS R5",
          "FNumber" => "28/10",
          "ExposureTime" => "1/250",
          "ISOSpeedRatings" => "400",
          "FocalLength" => "50/1"
        }
      end
    end

    trait :with_exif_nikon do
      exif_data do
        {
          "Make" => "Nikon",
          "Model" => "Nikon Z6",
          "FNumber" => "18/10",
          "ExposureTime" => "1/1000",
          "ISOSpeedRatings" => "200",
          "FocalLength" => "85/1"
        }
      end
    end

    trait :with_exif_model_only do
      exif_data do
        {
          "Model" => "iPhone 15 Pro"
        }
      end
    end
  end
end
