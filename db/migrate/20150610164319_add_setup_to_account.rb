class AddSetupToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :setup, :boolean, default: false
  end	
end