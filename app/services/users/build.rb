# frozen_string_literal: true

module Users
  class Build
    START_BALANCE = 1000

    def self.call(...) = new(...).call

    def initialize(params:, repo_name: 'User')
      @params = params
      @repo_name = repo_name
    end

    def call
      repo
        .new(params)
        .tap { |user| user.build_wallet(balance: START_BALANCE) }
    end

    private

    attr_reader :params, :repo_name

    def repo = @repo ||= repo_name.constantize
  end
end
