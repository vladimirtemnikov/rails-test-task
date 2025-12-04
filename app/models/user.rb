# frozen_string_literal: true

class User < ApplicationRecord
  has_many :orders, dependent: nil

  has_one :wallet, dependent: nil, autosave: true, required: true

  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  validates :email, presence: true

  delegate :balance, to: :wallet, prefix: true
end
