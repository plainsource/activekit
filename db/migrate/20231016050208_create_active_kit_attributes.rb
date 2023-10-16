class CreateActiveKitAttributes < ActiveRecord::Migration[6.1]
  def change
    create_table :active_kit_attributes do |t|
      t.references :record, polymorphic: true, index: true
      t.text       :value, size: :long
      t.timestamps
    end
  end
end
