class AddFreshdeskDetailsToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :integration_type, :string, default: "Zendesk"
    add_column :accounts, :freshdesk_url, :string
    add_column :accounts, :freshdesk_token, :string
  end
end
