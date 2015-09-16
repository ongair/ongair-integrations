class AddAuthMethodToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :auth_method, :string, default: "token_access"
  end	
end