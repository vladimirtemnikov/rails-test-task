# frozen_string_literal: true

class OrderPolicy < ApplicationPolicy
  relation_scope do |relation|
    relation.where(user:)
  end

  def show?
    user.id == record.user_id
  end

  def complete?
    show? && record.may_complete? && user.wallet_balance >= record.amount
  end

  def cancel?
    show? && record.may_cancel?
  end
end
