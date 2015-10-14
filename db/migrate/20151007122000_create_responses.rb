class CreateResponses < ActiveRecord::Migration
  def change
    create_table :responses do |t|
      t.references :account, index: true
      t.text :in_business_hours
      t.text :not_in_business_hours

      t.timestamps null: true
    end
  end
end
