class CreateBusinessHours < ActiveRecord::Migration
  def change
    create_table :business_hours do |t|
      t.references :account, index: true
      t.string :day
      t.string :from
      t.string :to
      t.boolean :work_day, default: true

      t.timestamps null: true
    end
  end
end
