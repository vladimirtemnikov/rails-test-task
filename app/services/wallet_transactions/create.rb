# frozen_string_literal: true

module WalletTransactions
  class Create
    def self.call(...) = new(...).call

    def initialize( # rubocop:disable Metrics/ParameterLists
      amount:,
      wallet_id:,
      order_id:,
      kind: :purchase,
      original_transaction_id: nil,
      idempotency_key: SecureRandom.uuid,
      repo_name: 'WalletTransaction'
    )
      @amount = amount
      @wallet_id = wallet_id
      @order_id = order_id
      @kind = kind
      @original_transaction_id = original_transaction_id
      @idempotency_key = idempotency_key
      @repo_name = repo_name
    end

    def call
      repo.create!(amount:, wallet_id:, order_id:, kind:, original_transaction_id:, idempotency_key:)
    end

    private

    attr_reader :amount, :wallet_id, :order_id, :kind, :original_transaction_id, :idempotency_key, :repo_name

    def repo = @repo ||= repo_name.constantize
  end
end
\
