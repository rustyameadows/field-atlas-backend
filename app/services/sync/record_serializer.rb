module Sync
  class RecordSerializer
    TYPE_CLASS_NAMES = {
      "user" => "User",
      "device" => "Device",
      "trip" => "Trip",
      "trip_member" => "TripMember",
      "trip_invite" => "TripInvite",
      "trip_segment" => "TripSegment",
      "trip_stop" => "TripStop",
      "trip_stop_option_link" => "TripStopOptionLink",
      "route_snapshot" => "RouteSnapshot",
      "route_snapshot_stop" => "RouteSnapshotStop",
      "route_leg" => "RouteLeg",
      "route_step" => "RouteStep",
      "favorite_place" => "FavoritePlace",
      "place_list" => "PlaceList",
      "place_list_item" => "PlaceListItem",
      "search_history_entry" => "SearchHistoryEntry",
      "search_session" => "SearchSession",
      "search_result_snapshot" => "SearchResultSnapshot",
      "user_setting" => "UserSetting",
      "memory_asset" => "MemoryAsset",
      "drive_session" => "DriveSession",
      "asset" => "Asset",
      "asset_link" => "AssetLink"
    }.freeze

    CLASS_TYPES = TYPE_CLASS_NAMES.to_h { |type, class_name| [ class_name, type ] }.freeze

    def self.type_for(record)
      CLASS_TYPES.fetch(record.class.name)
    end

    def self.class_for(type)
      TYPE_CLASS_NAMES.fetch(type).constantize
    end

    def self.trip_for(record)
      case record
      when Trip
        record
      when TripMember, TripInvite, TripSegment, TripStop, TripStopOptionLink, RouteSnapshot, MemoryAsset, DriveSession
        record.trip
      when AssetLink
        Assets::AttachableResolver.trip_for_link(record)
      when RouteSnapshotStop, RouteLeg
        record.route_snapshot.trip
      when RouteStep
        record.route_leg.route_snapshot.trip
      end
    end

    def self.user_for(record)
      case record
      when User
        record
      when Device, FavoritePlace, PlaceList, SearchHistoryEntry, SearchSession, UserSetting, MemoryAsset, DriveSession
        record.user
      when Asset
        record.uploaded_by_user
      when AssetLink
        Assets::AttachableResolver.new(user: nil).owner_user_for(record)
      when PlaceListItem
        record.place_list.user
      end
    end

    def self.serialize(record)
      {
        type: type_for(record),
        id: record.id,
        server_id: record.id,
        revision: record.respond_to?(:revision) ? record.revision : 1,
        deleted_at: iso(record.respond_to?(:deleted_at) ? record.deleted_at : nil),
        created_at: iso(record.created_at),
        updated_at: iso(record.updated_at),
        attributes: attributes_for(record)
      }
    end

    def self.attributes_for(record)
      case record
      when User
        record.slice(:display_name, :email, :email_verified, :time_zone, :status)
      when Device
        record.slice(:user_id, :client_device_id, :name, :platform, :app_version, :build_number, :push_environment, :last_seen_at)
      when Trip
        record.slice(:owner_user_id, :created_by_device_id, :client_id, :title, :start_date, :end_date, :encoded_workspace, :client_payload)
      when TripMember
        record.slice(:trip_id, :user_id, :display_name, :role, :status, :joined_at)
      when TripInvite
        record.slice(:trip_id, :invited_by_user_id, :accepted_by_user_id, :token, :url, :role, :status, :expires_at, :accepted_at)
      when TripSegment
        record.slice(:trip_id, :client_id, :title, :container_type, :segment_kind, :auto_day_index, :parent_segment_id, :start_date, :end_date, :sort_key, :color_token_id, :encoded_segment, :client_payload)
      when TripStop
        record.slice(:trip_id, :trip_segment_id, :created_by_user_id, :created_by_device_id, :canonical_place_id, :client_id, :item_id, :placement_id, :kind, :title, :subtitle, :notes, :sort_key, :place_title, :place_subtitle, :address, :latitude, :longitude, :source, :source_identifier, :provider, :provider_id, :source_ids, :location_target, :encoded_item, :encoded_placement, :client_payload)
      when TripStopOptionLink
        record.slice(:trip_id, :client_id, :group_id, :parent_stop_id, :candidate_stop_id, :group_title, :role, :status, :is_selected, :sort_key, :client_payload)
      when RouteSnapshot
        record.slice(:trip_id, :trip_segment_id, :created_by_user_id, :created_by_device_id, :client_id, :provider, :stale, :total_distance_meters, :expected_travel_time, :routing_signature, :encoded_route, :client_payload).merge(
          snapshot_stops: record.snapshot_stops.active.order(:sort_key).map { |child| attributes_for(child).merge(id: child.id, server_id: child.id, revision: child.revision) },
          legs: record.legs.active.order(:sort_key).map { |leg| attributes_for(leg).merge(id: leg.id, server_id: leg.id, revision: leg.revision) }
        )
      when RouteSnapshotStop
        record.slice(:route_snapshot_id, :trip_stop_id, :client_id, :kind, :sort_key, :latitude, :longitude, :title)
      when RouteLeg
        record.slice(:route_snapshot_id, :source_stop_id, :destination_stop_id, :client_id, :name, :label, :distance_meters, :expected_travel_time, :sort_key, :encoded_polyline).merge(
          steps: record.steps.active.order(:sort_key).map { |step| attributes_for(step).merge(id: step.id, server_id: step.id, revision: step.revision) }
        )
      when RouteStep
        record.slice(:route_leg_id, :client_id, :instructions, :notice, :distance_meters, :transport_type, :sort_key, :encoded_polyline)
      when FavoritePlace
        record.slice(:user_id, :client_id, :place_id, :name, :favorited_at, :encoded_place, :client_payload)
      when PlaceList
        record.slice(:user_id, :client_id, :name, :marker_shape, :marker_color_red, :marker_color_green, :marker_color_blue, :client_payload)
      when PlaceListItem
        record.slice(:place_list_id, :client_id, :place_id, :sort_key, :added_at, :encoded_place, :client_payload)
      when SearchHistoryEntry
        record.slice(:user_id, :client_id, :query, :searched_at, :latitude, :longitude, :encoded_entry, :client_payload)
      when SearchSession
        record.slice(:user_id, :search_history_entry_id, :client_id, :query, :encoded_session, :client_payload)
      when SearchResultSnapshot
        record.slice(:owner_type, :owner_id, :client_id, :place_id, :sort_key, :encoded_place, :client_payload)
      when UserSetting
        record.slice(:user_id, :key, :value)
      when MemoryAsset
        record.slice(:user_id, :trip_id, :drive_session_id, :client_id, :kind, :title, :local_file_name, :transcript, :transcript_status, :encoded_asset, :client_payload)
      when DriveSession
        record.slice(:user_id, :trip_id, :route_snapshot_id, :client_id, :started_at, :ended_at, :encoded_session, :client_payload)
      when Asset
        record.slice(:uploaded_by_user_id, :client_id, :asset_kind, :mime_type, :original_filename, :byte_size, :checksum, :storage_provider, :storage_key, :width, :height, :duration_ms, :status, :metadata)
      when AssetLink
        record.slice(:asset_id, :created_by_user_id, :attachable_type, :attachable_id, :attachable_ref, :role, :caption, :sort_order, :metadata)
      else
        {}
      end.transform_values { |value| normalize_value(value) }
    end

    def self.normalize_value(value)
      case value
      when Time, ActiveSupport::TimeWithZone
        iso(value)
      when Date
        value.iso8601
      else
        value
      end
    end

    def self.iso(value)
      value&.utc&.iso8601
    end
  end
end
