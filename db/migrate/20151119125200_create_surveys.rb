class CreateSurveys < ActiveRecord::Migration
  def change
    create_table :surveys do |t|
      t.references :user, index: true
      t.references :ticket, index: true
      t.references :account, index: true
      t.integer :rating
      t.string :comment
      t.boolean :completed, default: false

      t.timestamps null: true
    end
  end
end
