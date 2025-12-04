# frozen_string_literal: true

FactoryBot.define do
  factory :wallet_transaction do
    wallet
    order
    amount { 100 }
    kind { :deposit }
    idempotency_key { SecureRandom.uuid }

    trait :deposit do
      kind { :deposit }
      amount { 100 }
    end

    trait :purchase do
      kind { :purchase }
      amount { -100 }
    end

    trait :reversal do
      kind { :reversal }
      amount { 100 }
      transient do
        original_transaction { nil }
      end
      original_transaction_id { original_transaction&.id }
    end
  end
end
