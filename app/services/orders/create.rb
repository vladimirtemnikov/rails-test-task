# frozen_string_literal: true

module Orders
  class Create
    def self.call(...) = new(...).call

    def initialize(amount:, user_id:, repo_name: 'Order')
      @amount = amount
      @user_id = user_id
      @repo_name = repo_name
    end

    def call
      repo.create(amount:, user_id:)
    end

    private

    attr_reader :amount, :user_id, :repo_name

    def repo = @repo ||= repo_name.constantize
  end
end
