# frozen_string_literal: true

class Wallet < ApplicationRecord
  belongs_to :user

  has_many :wallet_transactions, dependent: nil
end
