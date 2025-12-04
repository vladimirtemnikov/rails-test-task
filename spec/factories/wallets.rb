# frozen_string_literal: true

FactoryBot.define do
  factory :wallet do
    user
    balance { 0 }
  end
end
