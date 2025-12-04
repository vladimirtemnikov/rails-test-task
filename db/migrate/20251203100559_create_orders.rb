# frozen_string_literal: true

class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :user, foreign_key: true, null: false
      t.string :status, null: false, default: 'created'
      t.decimal :amount, null: false

      t.timestamps
    end
  end
end
