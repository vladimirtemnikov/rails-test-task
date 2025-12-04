# frozen_string_literal: true

class Order < ApplicationRecord
  include AASM

  belongs_to :user

  has_one :purchase_transaction, class_name: 'WalletTransaction', dependent: nil

  aasm(column: 'status') do
    state :created, initial: true
    state :completed
    state :cancelled

    event :complete do
      transitions from: :created, to: :completed
    end

    event :cancel do
      transitions from: :completed, to: :cancelled
    end
  end

  with_options presence: true do
    validates :amount, numericality: { greater_than: 0 }
    validates :purchase_transaction, if: -> { completed? }
  end
end
