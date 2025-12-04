# frozen_string_literal: true

class WalletTransactionPolicy < ApplicationPolicy
  relation_scope do |relation|
    relation.where(wallet: user.wallet)
  end
end
