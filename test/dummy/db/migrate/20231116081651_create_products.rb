class CreateProducts < ActiveRecord::Migration[6.1]
  def change
    create_table :products do |t|
      t.string :name
      t.string :arrangement, index: true
      t.string :booking_date_arrangement, index: true

      t.timestamps
    end
  end
end
