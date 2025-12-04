# frozen_string_literal: true

module Orders
  class Complete
    class OrderNotFoundError < StandardError; end
    class InvalidOrderStateError < StandardError; end

    def self.call(...) = new(...).call

    def initialize(order_id:, repo_name: 'Order')
      @order_id = order_id
      @repo_name = repo_name
    end

    def call
      order = repo.find_by(id: order_id)
      raise OrderNotFoundError, "Order #{order_id} not found" unless order
      raise InvalidOrderStateError, "Order #{order_id} cannot be completed" unless order.may_complete?

      wallet = order.user.wallet
      amount = -order.amount

      ApplicationRecord.transaction do
        WalletTransactions::Create.call(amount:, kind: :purchase, wallet_id: wallet.id, order_id:)
        Wallets::ChangeBalance.call(amount:, wallet_id: wallet.id)
        order.complete!
      end
    rescue Wallets::InsufficientFundsError
      raise
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("Failed to complete order #{order_id}: #{e.message}")
      raise
    end

    private

    attr_reader :order_id, :repo_name

    def repo = @repo ||= repo_name.constantize
  end
end
