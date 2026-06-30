class CreatePlaceContainments < ActiveRecord::Migration[8.1]
  def change
    create_table :place_containments do |t|
      t.references :containing_place, null: false, foreign_key: { to_table: :places }
      t.references :source_record, null: false, foreign_key: true
      t.string :relationship_type, null: false, default: "contains"
      t.decimal :confidence, precision: 5, scale: 4, null: false, default: 0
      t.string :review_status, null: false, default: "auto"

      t.timestamps
    end

    add_index :place_containments, [ :containing_place_id, :source_record_id ], unique: true
    add_index :place_containments, :relationship_type
    add_index :place_containments, :review_status
  end
end
