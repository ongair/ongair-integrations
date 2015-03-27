class CreateTickets < ActiveRecord::Migration
  def change
    create_table :tickets do |t|
      t.string :phone_number
      t.string :ticket_id
      t.string :status
      t.string :source
      t.references :account, index: true

      t.timestamps null: true
    end
  end
end
