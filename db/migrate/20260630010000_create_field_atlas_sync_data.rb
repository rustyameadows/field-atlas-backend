class CreateFieldAtlasSyncData < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    create_table :users, id: :uuid do |t|
      t.string :display_name
      t.string :email
      t.boolean :email_verified, null: false, default: false
      t.string :time_zone
      t.string :status, null: false, default: "active"
      t.datetime :deleted_at
      t.integer :revision, null: false, default: 1

      t.timestamps
    end
    add_index :users, :email
    add_index :users, :status

    create_table :user_auth_identities, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.string :provider, null: false
      t.string :provider_subject, null: false
      t.string :email
      t.boolean :email_verified, null: false, default: false
      t.string :display_name
      t.jsonb :raw_claims, null: false, default: {}
      t.datetime :last_verified_at

      t.timestamps
    end
    add_index :user_auth_identities, [ :provider, :provider_subject ], unique: true, name: "idx_auth_identities_provider_subject"

    create_table :devices, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.string :client_device_id, null: false
      t.string :name
      t.string :platform, null: false, default: "ios"
      t.string :app_version
      t.string :build_number
      t.string :push_token
      t.string :push_environment
      t.datetime :last_seen_at
      t.datetime :deleted_at
      t.integer :revision, null: false, default: 1

      t.timestamps
    end
    add_index :devices, [ :user_id, :client_device_id ], unique: true
    add_index :devices, :last_seen_at

    create_table :api_sessions, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.references :device, type: :uuid, foreign_key: true
      t.string :access_token_digest, null: false
      t.string :refresh_token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :refresh_expires_at, null: false
      t.datetime :last_used_at
      t.datetime :revoked_at

      t.timestamps
    end
    add_index :api_sessions, :access_token_digest, unique: true
    add_index :api_sessions, :refresh_token_digest, unique: true
    add_index :api_sessions, :expires_at

    create_table :trips, id: :uuid do |t|
      t.references :owner_user, null: false, type: :uuid, foreign_key: { to_table: :users }
      t.references :created_by_device, type: :uuid, foreign_key: { to_table: :devices }
      t.string :client_id
      t.string :title, null: false
      t.date :start_date
      t.date :end_date
      t.datetime :deleted_at
      t.integer :revision, null: false, default: 1
      t.jsonb :encoded_workspace, null: false, default: {}
      t.jsonb :client_payload, null: false, default: {}

      t.timestamps
    end
    add_index :trips, :client_id
    add_index :trips, :deleted_at

    create_table :trip_members, id: :uuid do |t|
      t.references :trip, null: false, type: :uuid, foreign_key: true
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.string :display_name
      t.string :role, null: false, default: "viewer"
      t.string :status, null: false, default: "active"
      t.datetime :joined_at, null: false
      t.datetime :deleted_at
      t.integer :revision, null: false, default: 1

      t.timestamps
    end
    add_index :trip_members, [ :trip_id, :user_id ], unique: true
    add_index :trip_members, [ :user_id, :status ]

    create_table :trip_invites, id: :uuid do |t|
      t.references :trip, null: false, type: :uuid, foreign_key: true
      t.references :invited_by_user, null: false, type: :uuid, foreign_key: { to_table: :users }
      t.references :accepted_by_user, type: :uuid, foreign_key: { to_table: :users }
      t.string :token, null: false
      t.string :url
      t.string :role, null: false, default: "editor"
      t.string :status, null: false, default: "pending"
      t.datetime :expires_at
      t.datetime :accepted_at
      t.datetime :deleted_at
      t.integer :revision, null: false, default: 1

      t.timestamps
    end
    add_index :trip_invites, :token, unique: true
    add_index :trip_invites, [ :trip_id, :status ]

    create_table :trip_segments, id: :uuid do |t|
      t.references :trip, null: false, type: :uuid, foreign_key: true
      t.string :client_id
      t.string :title, null: false
      t.string :container_type
      t.string :segment_kind
      t.integer :auto_day_index
      t.references :parent_segment, type: :uuid, foreign_key: { to_table: :trip_segments }
      t.date :start_date
      t.date :end_date
      t.float :sort_key, null: false, default: 0
      t.string :color_token_id
      t.jsonb :encoded_segment, null: false, default: {}
      t.datetime :deleted_at
      t.integer :revision, null: false, default: 1
      t.jsonb :client_payload, null: false, default: {}

      t.timestamps
    end
    add_index :trip_segments, [ :trip_id, :sort_key ]
    add_index :trip_segments, [ :trip_id, :client_id ]

    create_table :trip_stops, id: :uuid do |t|
      t.references :trip, null: false, type: :uuid, foreign_key: true
      t.references :trip_segment, type: :uuid, foreign_key: true
      t.references :created_by_user, type: :uuid, foreign_key: { to_table: :users }
      t.references :created_by_device, type: :uuid, foreign_key: { to_table: :devices }
      t.references :canonical_place, type: :bigint, foreign_key: { to_table: :places }
      t.string :client_id
      t.string :item_id
      t.string :placement_id
      t.string :kind, null: false
      t.string :title, null: false
      t.string :subtitle
      t.text :notes
      t.float :sort_key, null: false, default: 0
      t.string :place_title
      t.string :place_subtitle
      t.string :address
      t.float :latitude
      t.float :longitude
      t.string :source
      t.string :source_identifier
      t.string :provider
      t.string :provider_id
      t.jsonb :source_ids, null: false, default: {}
      t.jsonb :location_target, null: false, default: {}
      t.jsonb :encoded_item, null: false, default: {}
      t.jsonb :encoded_placement, null: false, default: {}
      t.datetime :deleted_at
      t.integer :revision, null: false, default: 1
      t.jsonb :client_payload, null: false, default: {}

      t.timestamps
    end
    add_index :trip_stops, [ :trip_id, :sort_key ]
    add_index :trip_stops, [ :trip_id, :kind ]
    add_index :trip_stops, [ :trip_id, :client_id ]

    create_table :trip_stop_option_links, id: :uuid do |t|
      t.references :trip, null: false, type: :uuid, foreign_key: true
      t.string :client_id
      t.string :group_id, null: false
      t.references :parent_stop, null: false, type: :uuid, foreign_key: { to_table: :trip_stops }
      t.references :candidate_stop, null: false, type: :uuid, foreign_key: { to_table: :trip_stops }
      t.string :group_title
      t.string :role
      t.string :status
      t.boolean :is_selected, null: false, default: false
      t.float :sort_key, null: false, default: 0
      t.datetime :deleted_at
      t.integer :revision, null: false, default: 1
      t.jsonb :client_payload, null: false, default: {}

      t.timestamps
    end
    add_index :trip_stop_option_links, [ :trip_id, :group_id, :sort_key ], name: "idx_option_links_trip_group_sort"
    add_index :trip_stop_option_links, [ :trip_id, :client_id ]

    create_table :route_snapshots, id: :uuid do |t|
      t.references :trip, null: false, type: :uuid, foreign_key: true
      t.references :trip_segment, type: :uuid, foreign_key: true
      t.references :created_by_user, type: :uuid, foreign_key: { to_table: :users }
      t.references :created_by_device, type: :uuid, foreign_key: { to_table: :devices }
      t.string :client_id
      t.string :provider, null: false, default: "apple-mapkit"
      t.boolean :stale, null: false, default: false
      t.float :total_distance_meters, null: false, default: 0
      t.float :expected_travel_time, null: false, default: 0
      t.jsonb :routing_signature, null: false, default: {}
      t.jsonb :encoded_route, null: false, default: {}
      t.datetime :deleted_at
      t.integer :revision, null: false, default: 1
      t.jsonb :client_payload, null: false, default: {}

      t.timestamps
    end
    add_index :route_snapshots, [ :trip_id, :trip_segment_id ]
    add_index :route_snapshots, [ :trip_id, :client_id ]

    create_table :route_snapshot_stops, id: :uuid do |t|
      t.references :route_snapshot, null: false, type: :uuid, foreign_key: true
      t.references :trip_stop, type: :uuid, foreign_key: true
      t.string :client_id
      t.string :kind, null: false
      t.float :sort_key, null: false, default: 0
      t.float :latitude
      t.float :longitude
      t.string :title, null: false
      t.datetime :deleted_at
      t.integer :revision, null: false, default: 1

      t.timestamps
    end

    create_table :route_legs, id: :uuid do |t|
      t.references :route_snapshot, null: false, type: :uuid, foreign_key: true
      t.references :source_stop, type: :uuid, foreign_key: { to_table: :trip_stops }
      t.references :destination_stop, type: :uuid, foreign_key: { to_table: :trip_stops }
      t.string :client_id
      t.string :name
      t.string :label
      t.float :distance_meters, null: false, default: 0
      t.float :expected_travel_time, null: false, default: 0
      t.float :sort_key, null: false, default: 0
      t.jsonb :encoded_polyline, null: false, default: {}
      t.datetime :deleted_at
      t.integer :revision, null: false, default: 1

      t.timestamps
    end

    create_table :route_steps, id: :uuid do |t|
      t.references :route_leg, null: false, type: :uuid, foreign_key: true
      t.string :client_id
      t.text :instructions, null: false
      t.text :notice
      t.float :distance_meters, null: false, default: 0
      t.string :transport_type
      t.float :sort_key, null: false, default: 0
      t.jsonb :encoded_polyline, null: false, default: {}
      t.datetime :deleted_at
      t.integer :revision, null: false, default: 1

      t.timestamps
    end

    create_user_data_tables
    create_sync_tables
  end

  private

  def create_user_data_tables
    create_table :favorite_places, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.string :client_id
      t.string :place_id, null: false
      t.string :name
      t.datetime :favorited_at
      t.jsonb :encoded_place, null: false, default: {}
      t.datetime :deleted_at
      t.integer :revision, null: false, default: 1
      t.jsonb :client_payload, null: false, default: {}
      t.timestamps
    end

    create_table :place_lists, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.string :client_id
      t.string :name, null: false
      t.string :marker_shape
      t.float :marker_color_red
      t.float :marker_color_green
      t.float :marker_color_blue
      t.datetime :deleted_at
      t.integer :revision, null: false, default: 1
      t.jsonb :client_payload, null: false, default: {}
      t.timestamps
    end

    create_table :place_list_items, id: :uuid do |t|
      t.references :place_list, null: false, type: :uuid, foreign_key: true
      t.string :client_id
      t.string :place_id, null: false
      t.float :sort_key, null: false, default: 0
      t.datetime :added_at
      t.jsonb :encoded_place, null: false, default: {}
      t.datetime :deleted_at
      t.integer :revision, null: false, default: 1
      t.jsonb :client_payload, null: false, default: {}
      t.timestamps
    end

    create_table :search_history_entries, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.string :client_id
      t.string :query, null: false
      t.datetime :searched_at
      t.float :latitude
      t.float :longitude
      t.jsonb :encoded_entry, null: false, default: {}
      t.datetime :deleted_at
      t.integer :revision, null: false, default: 1
      t.jsonb :client_payload, null: false, default: {}
      t.timestamps
    end

    create_table :search_sessions, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.references :search_history_entry, type: :uuid, foreign_key: true
      t.string :client_id
      t.string :query, null: false
      t.jsonb :encoded_session, null: false, default: {}
      t.datetime :deleted_at
      t.integer :revision, null: false, default: 1
      t.jsonb :client_payload, null: false, default: {}
      t.timestamps
    end

    create_table :search_result_snapshots, id: :uuid do |t|
      t.string :owner_type, null: false
      t.uuid :owner_id, null: false
      t.string :client_id
      t.string :place_id, null: false
      t.float :sort_key, null: false, default: 0
      t.jsonb :encoded_place, null: false, default: {}
      t.datetime :deleted_at
      t.integer :revision, null: false, default: 1
      t.jsonb :client_payload, null: false, default: {}
      t.timestamps
    end

    create_table :user_settings, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.string :key, null: false
      t.text :value
      t.datetime :deleted_at
      t.integer :revision, null: false, default: 1
      t.timestamps
    end
    add_index :user_settings, [ :user_id, :key ], unique: true

    create_table :memory_assets, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.references :trip, type: :uuid, foreign_key: true
      t.references :drive_session, type: :uuid
      t.string :client_id
      t.string :kind, null: false
      t.string :title
      t.string :local_file_name
      t.text :transcript
      t.string :transcript_status
      t.jsonb :encoded_asset, null: false, default: {}
      t.datetime :deleted_at
      t.integer :revision, null: false, default: 1
      t.jsonb :client_payload, null: false, default: {}
      t.timestamps
    end

    create_table :drive_sessions, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.references :trip, type: :uuid, foreign_key: true
      t.references :route_snapshot, type: :uuid, foreign_key: true
      t.string :client_id
      t.datetime :started_at
      t.datetime :ended_at
      t.jsonb :encoded_session, null: false, default: {}
      t.datetime :deleted_at
      t.integer :revision, null: false, default: 1
      t.jsonb :client_payload, null: false, default: {}
      t.timestamps
    end
    add_foreign_key :memory_assets, :drive_sessions

    add_index :favorite_places, [ :user_id, :client_id ]
    add_index :place_lists, [ :user_id, :client_id ]
    add_index :search_history_entries, [ :user_id, :client_id ]
    add_index :search_sessions, [ :user_id, :client_id ]
    add_index :memory_assets, [ :user_id, :client_id ]
    add_index :drive_sessions, [ :user_id, :client_id ]
  end

  def create_sync_tables
    create_table :client_operations, id: :uuid do |t|
      t.string :operation_id, null: false
      t.references :device, null: false, type: :uuid, foreign_key: true
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.string :entity_type, null: false
      t.string :entity_id, null: false
      t.string :action, null: false
      t.jsonb :payload, null: false, default: {}
      t.integer :base_revision
      t.datetime :client_created_at
      t.datetime :received_at, null: false
      t.datetime :processed_at
      t.string :status
      t.jsonb :result, null: false, default: {}
      t.string :error_code
      t.text :message
      t.timestamps
    end
    add_index :client_operations, [ :device_id, :operation_id ], unique: true

    create_table :sync_events do |t|
      t.uuid :event_uuid, null: false, default: -> { "gen_random_uuid()" }
      t.string :entity_type, null: false
      t.uuid :entity_id, null: false
      t.references :trip, type: :uuid, foreign_key: true
      t.references :user, type: :uuid, foreign_key: true
      t.references :actor_user, type: :uuid, foreign_key: { to_table: :users }
      t.references :actor_device, type: :uuid, foreign_key: { to_table: :devices }
      t.string :action, null: false
      t.integer :record_revision, null: false
      t.datetime :occurred_at, null: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end
    add_index :sync_events, :event_uuid, unique: true
    add_index :sync_events, :occurred_at
    add_index :sync_events, [ :entity_type, :entity_id ]

    create_table :deleted_records, id: :uuid do |t|
      t.string :entity_type, null: false
      t.uuid :entity_id, null: false
      t.references :trip, type: :uuid, foreign_key: true
      t.references :user, type: :uuid, foreign_key: true
      t.datetime :deleted_at, null: false
      t.integer :revision, null: false, default: 1
      t.references :deleted_by_user, type: :uuid, foreign_key: { to_table: :users }
      t.references :deleted_by_device, type: :uuid, foreign_key: { to_table: :devices }
      t.string :reason, null: false, default: "deleted"
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end
    add_index :deleted_records, [ :entity_type, :entity_id ]
  end
end
