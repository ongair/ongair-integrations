require_relative '../../environment'
class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.string :zendesk_url
      t.string :zendesk_access_token
      t.string :ongair_token

      t.timestamps
    end
  end
end
