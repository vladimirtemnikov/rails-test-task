# frozen_string_literal: true

module WalletTransactions
  class Reverse
    def self.call(...) = new(...).call

    def initialize(id:, repo_name: 'WalletTransaction')
      @id = id
      @repo_name = repo_name
    end

    def call
      original = repo.find(id)
      Create.call(
        amount: -original.amount,
        original_transaction_id: id,
        kind: :reversal,
        **original.slice(:wallet_id, :order_id).symbolize_keys
      )
    end

    private

    attr_reader :id, :repo_name

    def repo = @repo ||= repo_name.constantize
  end
end
