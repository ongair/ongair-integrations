class AddFieldsToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :ticket_end_status, :string, default: "4"
    add_column :accounts, :ticket_closed_notification, :string
  end	
end