# frozen_string_literal: true

class CompleteOrderJob < ApplicationJob
  retry_on Wallets::InsufficientFundsError, wait: 0, attempts: 1

  def perform(order_id:)
    Orders::Complete.call(order_id:)
  rescue Wallets::InsufficientFundsError => e
    Rails.logger.error("Failed to complete order #{order_id}: #{e.message}")
    raise e
  end
end
