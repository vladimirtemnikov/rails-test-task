# frozen_string_literal: true

class CancelOrderJob < ApplicationJob
  def perform(order_id:)
    Orders::Cancel.call(order_id:)
  rescue StandardError => e
    Rails.logger.error("Failed to create order: #{e.message}")
    raise
  end
end
