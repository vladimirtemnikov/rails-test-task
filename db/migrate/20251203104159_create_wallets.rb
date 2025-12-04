# frozen_string_literal: true

class CreateWallets < ActiveRecord::Migration[8.1]
  def change
    create_table :wallets do |t|
      t.references :user, foreign_key: true, null: false, index: { unique: true }

      t.decimal :balance, default: 0, null: false

      t.timestamps
    end

    add_check_constraint :wallets, 'balance >= 0', name: 'check_balance_non_negative'
  end
end
