class AddTimezoneToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :timezone, :string
  end	
end