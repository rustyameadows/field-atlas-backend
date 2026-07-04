class CreateAssets < ActiveRecord::Migration[8.1]
  def change
    create_table :assets, id: :uuid do |t|
      t.references :uploaded_by_user, null: false, type: :uuid, foreign_key: { to_table: :users }
      t.string :client_id
      t.string :asset_kind, null: false
      t.string :mime_type, null: false
      t.string :original_filename
      t.bigint :byte_size, null: false, default: 0
      t.string :checksum
      t.string :storage_provider, null: false, default: "r2"
      t.string :storage_key, null: false
      t.integer :width
      t.integer :height
      t.integer :duration_ms
      t.string :status, null: false, default: "awaiting_upload"
      t.jsonb :metadata, null: false, default: {}
      t.integer :revision, null: false, default: 1
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :assets, [ :uploaded_by_user_id, :created_at ]
    add_index :assets, [ :uploaded_by_user_id, :client_id ], unique: true, where: "client_id IS NOT NULL"
    add_index :assets, :storage_key, unique: true
    add_index :assets, [ :status, :created_at ]
    add_index :assets, :deleted_at

    create_table :asset_links, id: :uuid do |t|
      t.references :asset, null: false, type: :uuid, foreign_key: true
      t.references :created_by_user, null: false, type: :uuid, foreign_key: { to_table: :users }
      t.string :attachable_type, null: false
      t.string :attachable_id
      t.jsonb :attachable_ref, null: false, default: {}
      t.string :role, null: false, default: "gallery"
      t.text :caption
      t.float :sort_order, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}
      t.integer :revision, null: false, default: 1
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :asset_links, [ :created_by_user_id, :created_at ]
    add_index :asset_links, [ :attachable_type, :attachable_id, :role, :deleted_at, :sort_order ], name: "idx_asset_links_attachable_role_deleted_sort"
    add_index :asset_links, :deleted_at
  end
end
