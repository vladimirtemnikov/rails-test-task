# frozen_string_literal: true

class CreateWalletTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :wallet_transactions do |t|
      t.references :wallet, foreign_key: true, null: false
      t.references :order, foreign_key: true, null: false

      t.decimal :amount, null: false
      t.integer :kind, null: false
      t.string :idempotency_key, null: false, index: { unique: true }
      t.bigint :original_transaction_id

      t.timestamps
    end
  end
end
