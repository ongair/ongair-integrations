class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :messaging_service
      t.string :phone_number
      t.string :zendesk_id

      t.timestamps null: true
    end
  end
end
