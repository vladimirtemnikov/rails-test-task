# frozen_string_literal: true

class SafeWalletBalanceUpdateQuery
  def initialize(amount:, id: nil, repo_name: 'Wallet')
    @amount = amount
    @id = id
    @repo_name = repo_name
  end

  def run
    repo
      .where(id:)
      .then { |rel| amount.negative? ? rel.where(balance: -amount..) : rel }
      .update_all(['balance = balance + ?', amount.to_d]) # rubocop:disable Rails/SkipsModelValidations
  end

  private

  attr_reader :amount, :id, :repo_name

  def repo = @repo ||= repo_name.constantize
end
