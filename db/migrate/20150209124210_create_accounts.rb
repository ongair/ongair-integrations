class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.string :zendesk_url
      t.string :zendesk_access_token
      t.string :zendesk_user
      t.string :ongair_token
      t.string :ongair_phone_number
      t.string :ongair_url
      t.string :zendesk_ticket_auto_responder

      t.timestamps null: true
    end
  end
end
