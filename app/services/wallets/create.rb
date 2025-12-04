# frozen_string_literal: true

module Wallets
  class Create
    def self.call(...) = new(...).call

    def initialize(user_id:, balance: 0, repo_name: 'Wallet')
      @user_id = user_id
      @balance = balance
      @repo_name = repo_name
    end

    def call
      repo.create!(balance:, user_id:)
    end

    private

    attr_reader :user_id, :balance, :repo_name

    def repo = @repo ||= repo_name.constantize
  end
end
