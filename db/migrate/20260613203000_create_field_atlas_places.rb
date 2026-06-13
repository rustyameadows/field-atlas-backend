class CreateFieldAtlasPlaces < ActiveRecord::Migration[8.1]
  def change
    enable_extension "postgis" unless extension_enabled?("postgis")

    create_table :places do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :kind, null: false
      t.string :status, null: false, default: "draft"
      t.string :primary_category
      t.geometry :geometry, geographic: true
      t.st_point :centroid, geographic: true
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end
    add_index :places, :slug, unique: true
    add_index :places, :kind
    add_index :places, :status
    add_index :places, :geometry, using: :gist
    add_index :places, :centroid, using: :gist

    create_table :source_datasets do |t|
      t.string :provider, null: false
      t.string :name, null: false
      t.string :source_url
      t.string :freshness_mode, null: false
      t.datetime :last_checked_at
      t.string :status, null: false, default: "active"

      t.timestamps
    end
    add_index :source_datasets, [ :provider, :name ], unique: true
    add_index :source_datasets, :provider

    create_table :source_records do |t|
      t.references :source_dataset, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :record_type, null: false
      t.string :source_id, null: false
      t.string :name, null: false
      t.string :normalized_name, null: false
      t.geometry :geometry, geographic: true
      t.st_point :centroid, geographic: true
      t.jsonb :raw_payload, null: false, default: {}
      t.jsonb :normalized_payload, null: false, default: {}
      t.string :payload_hash, null: false
      t.datetime :fetched_at, null: false
      t.datetime :expires_at

      t.timestamps
    end
    add_index :source_records, [ :provider, :record_type, :source_id ], unique: true
    add_index :source_records, [ :provider, :record_type ]
    add_index :source_records, :normalized_name
    add_index :source_records, :geometry, using: :gist
    add_index :source_records, :centroid, using: :gist

    create_table :place_source_links do |t|
      t.references :place, null: false, foreign_key: true
      t.references :source_record, null: false, foreign_key: true
      t.string :match_type, null: false
      t.decimal :confidence, precision: 5, scale: 4, null: false, default: 0
      t.string :review_status, null: false, default: "auto"

      t.timestamps
    end
    add_index :place_source_links, [ :place_id, :source_record_id ], unique: true
    add_index :place_source_links, :review_status

    create_table :park_units do |t|
      t.references :place, null: false, foreign_key: true
      t.string :agency, null: false
      t.string :designation
      t.string :states, array: true, null: false, default: []
      t.string :official_code
      t.string :source_provider

      t.timestamps
    end
    add_index :park_units, [ :agency, :official_code ]
  end
end
