# frozen_string_literal: true

class CreateOrderJob < ApplicationJob
  def perform(amount:, user_id:)
    Orders::Create.call(amount:, user_id:)
  rescue StandardError => e
    Rails.logger.error("Failed to create order: #{e.message}")
    raise
  end
end
