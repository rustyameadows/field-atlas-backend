class CreatePlaceExternalIdentifiers < ActiveRecord::Migration[8.1]
  def change
    create_table :place_external_identifiers do |t|
      t.references :place, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :identifier, null: false
      t.string :identifier_kind, null: false, default: "primary"
      t.string :review_status, null: false, default: "verified"

      t.timestamps
    end

    add_index :place_external_identifiers, [ :provider, :identifier ], unique: true
    add_index :place_external_identifiers, [ :place_id, :provider ]
    add_index :place_external_identifiers, :review_status
  end
end
