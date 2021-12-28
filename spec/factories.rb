# frozen_string_literal: true

# This will guess the User class

require "faker"

FactoryBot.define do
  sequence(:ext) { [".rb", ".js", ".html", ".css", ".md"].sample }
  sequence(:file) { Faker::File.file_name(ext: "rb") }
  sequence(:email) { Faker::Internet.email }
  sequence(:hash) { Faker::Crypto.md5 }
  sequence(:name) { Faker::Name.name }
  sequence(:time) { Faker::Time.between(from: DateTime.now - 1, to: DateTime.now) }
  sequence(:number) { Faker::Number.number(digits: 2) }
  sequence(:change) do
    {
      file_path: Pathname(FactoryBot.generate(:file)),
      final_signature: {
        time: FactoryBot.generate(:time),
        email: FactoryBot.generate(:email),
        name: FactoryBot.generate(:name)
      },
      final_commit_id: FactoryBot.generate(:hash),
      lines_in_hunk: FactoryBot.generate(:number)
    }
  end

  sequence(:diff) do
    Array.new(rand(2..5)) { FactoryBot.generate(:change) }
  end

  initialize_with { new(**attributes) }

  factory :render, class: "GitFame::Render" do
    branch { "HEAD" }
    result
  end

  factory :filter, class: "GitFame::Filter" do
    trait :all do
      before { Faker::DateTime.backward(days: 365) }

      after { Faker::DateTime.forward(days: 365) }

      extensions { Array.new(2) { generate(:ext) } }
    end
  end

  factory :collector, class: "GitFame::Collector" do
    filter
    diff
  end

  factory :author, class: "GitFame::Author" do
    name
    email
  end

  factory :contribution, class: "GitFame::Contribution" do
    commits { Array.new(3) { generate(:hash) } }
    files { Array.new(3) { generate(:file) } }
    lines { generate(:number) }
    author
  end

  factory :result, class: "GitFame::Result" do
    contributions { build_list(:contribution, 3) }
  end
end
