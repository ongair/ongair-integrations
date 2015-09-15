class AddClientToAccount < ActiveRecord::Migration
  def change
    # add_reference :accounts, :client, index: true
    # add_foreign_key :accounts, :client
  end	
end