# frozen_string_literal: true

class WalletTransactionsController < ApplicationController
  before_action :authenticate_user!

  def index
    wallet_transactions = authorized_scope(WalletTransaction.includes(:order).order(id: :desc))

    render :index, locals: { wallet_transactions: }
  end
end
