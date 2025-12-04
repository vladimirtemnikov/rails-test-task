# frozen_string_literal: true

class WalletTransaction < ApplicationRecord
  belongs_to :wallet
  belongs_to :order

  enum :kind, { deposit: 0, purchase: 1, reversal: 2 }, validate: true

  with_options presence: true do
    validates :amount
    validates :idempotency_key
    validates :original_transaction_id, if: -> { reversal? }
  end
end
