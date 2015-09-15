class AddDetectLanguageToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :detect_language, :boolean, default: false
  end	
end