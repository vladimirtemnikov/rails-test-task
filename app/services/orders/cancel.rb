# frozen_string_literal: true

module Orders
  class Cancel
    class OrderNotFoundError < StandardError; end
    class InvalidOrderStateError < StandardError; end
    class MissingPurchaseTransactionError < StandardError; end

    def self.call(...) = new(...).call

    def initialize(order_id:, repo_name: 'Order')
      @order_id = order_id
      @repo_name = repo_name
    end

    def call
      order = repo.find_by(id: order_id)
      raise OrderNotFoundError, "Order #{order_id} not found" unless order
      raise InvalidOrderStateError, "Order #{order_id} cannot be cancelled" unless order.may_cancel?

      unless order.purchase_transaction
        raise MissingPurchaseTransactionError,
              "Order #{order_id} has no purchase transaction"
      end

      wallet = order.user.wallet
      amount = order.amount

      ApplicationRecord.transaction do
        WalletTransactions::Reverse.call(id: order.purchase_transaction.id)
        Wallets::ChangeBalance.call(amount:, wallet_id: wallet.id)
        order.cancel!
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("Failed to cancel order #{order_id}: #{e.message}")
      raise
    end

    private

    attr_reader :order_id, :repo_name

    def repo = @repo ||= repo_name.constantize
  end
end
