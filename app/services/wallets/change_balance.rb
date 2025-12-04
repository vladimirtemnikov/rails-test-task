# frozen_string_literal: true

module Wallets
  class ChangeBalance
    def self.call(...) = new(...).call

    def initialize(amount:, wallet_id:, repo_name: 'Wallet')
      @amount = amount
      @wallet_id = wallet_id
      @repo_name = repo_name
    end

    def call
      query = SafeWalletBalanceUpdateQuery.new(id: wallet_id, amount:, repo_name:)
      updated = query.run
      raise InsufficientFundsError if amount.negative? && updated.zero?
    rescue ActiveRecord::CheckViolation
      raise InsufficientFundsError
    end

    private

    attr_reader :amount, :wallet_id, :repo_name

    def repo = @repo ||= repo_name.constantize
  end
end
