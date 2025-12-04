# frozen_string_literal: true

FactoryBot.define do
  factory :order do
    user
    amount { 100 }
    status { 'created' }

    trait :completed do
      status { 'completed' }
      after(:create) do |order|
        create(:wallet_transaction, :purchase, order:, wallet: order.user.wallet)
        order.update(purchase_transaction: order.wallet_transactions.last)
      end
    end

    trait :cancelled do
      status { 'cancelled' }
    end
  end
end
