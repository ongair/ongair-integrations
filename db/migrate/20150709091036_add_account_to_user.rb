class AddAccountToUser < ActiveRecord::Migration
  def change
    add_reference :users, :account, index: true
    add_foreign_key :users, :accounts
  end
end
