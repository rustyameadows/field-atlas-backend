module Sync
  class AccessScope
    TRIP_MODELS = [
      Trip, TripMember, TripInvite, TripSegment, TripStop, TripStopOptionLink,
      RouteSnapshot, RouteSnapshotStop, RouteLeg, RouteStep
    ].freeze

    USER_MODELS = [
      Device, FavoritePlace, PlaceList, PlaceListItem, SearchHistoryEntry,
      SearchSession, SearchResultSnapshot, UserSetting, MemoryAsset, DriveSession
    ].freeze

    ASSET_MODELS = [
      Asset, AssetLink
    ].freeze

    def initialize(user:)
      @user = user
    end

    def active_trip_ids
      @active_trip_ids ||= Trip.active.where(owner_user: @user)
                         .or(Trip.active.where(id: TripMember.active.where(user: @user).select(:trip_id)))
                         .select(:id)
    end

    def active_trip?(trip_id)
      return false if trip_id.blank?

      active_trip_ids.exists?(id: trip_id)
    end

    def visible_records
      trip_ids = active_trip_ids
      records = []
      records << @user
      records.concat Device.active.where(user: @user).to_a
      records.concat Trip.active.where(id: trip_ids).to_a
      records.concat TripMember.active.where(trip_id: trip_ids).to_a
      records.concat TripInvite.where(trip_id: trip_ids, deleted_at: nil).to_a
      records.concat TripSegment.active.where(trip_id: trip_ids).to_a
      records.concat TripStop.active.where(trip_id: trip_ids).to_a
      records.concat TripStopOptionLink.active.where(trip_id: trip_ids).to_a

      snapshots = RouteSnapshot.active.where(trip_id: trip_ids)
      records.concat snapshots.to_a
      records.concat RouteSnapshotStop.active.where(route_snapshot_id: snapshots.select(:id)).to_a
      records.concat RouteLeg.active.where(route_snapshot_id: snapshots.select(:id)).to_a
      records.concat RouteStep.active.where(route_leg_id: RouteLeg.active.where(route_snapshot_id: snapshots.select(:id)).select(:id)).to_a

      records.concat FavoritePlace.active.where(user: @user).to_a
      lists = PlaceList.active.where(user: @user)
      records.concat lists.to_a
      records.concat PlaceListItem.active.where(place_list_id: lists.select(:id)).to_a
      records.concat SearchHistoryEntry.active.where(user: @user).to_a
      sessions = SearchSession.active.where(user: @user)
      records.concat sessions.to_a
      records.concat SearchResultSnapshot.active.where(owner_type: "SearchSession", owner_id: sessions.select(:id)).to_a
      records.concat UserSetting.active.where(user: @user).to_a
      records.concat MemoryAsset.active.where(user: @user).to_a
      records.concat DriveSession.active.where(user: @user).to_a
      visible_links = visible_asset_links
      records.concat visible_links
      records.concat visible_assets_for(visible_links)
      records
    end

    def visible_record(type, id)
      record = RecordSerializer.class_for(type).find_by(id: id)
      return if record.blank?

      visible?(record) ? record : nil
    end

    def visible?(record)
      return record.id == @user.id if record.is_a?(User)

      if TRIP_MODELS.any? { |model| record.is_a?(model) }
        trip = RecordSerializer.trip_for(record)
        return trip.present? && trip.readable_by?(@user)
      end

      if USER_MODELS.any? { |model| record.is_a?(model) }
        owner = RecordSerializer.user_for(record)
        return owner == @user
      end

      if ASSET_MODELS.any? { |model| record.is_a?(model) }
        resolver = Assets::AttachableResolver.new(user: @user)
        return resolver.visible_asset?(record) if record.is_a?(Asset)
        return resolver.readable_link?(record)
      end

      false
    end

    def deleted_records
      DeletedRecord.where(user: @user).or(DeletedRecord.where(trip_id: active_trip_ids))
    end

    private

    def visible_asset_links
      links = []
      trip_ids = active_trip_ids.pluck(:id).map(&:to_s)
      links.concat AssetLink.active.where(attachable_type: "Trip", attachable_id: trip_ids).to_a if trip_ids.any?

      trip_stop_ids = TripStop.active.where(trip_id: active_trip_ids).pluck(:id).map(&:to_s)
      links.concat AssetLink.active.where(attachable_type: "TripStop", attachable_id: trip_stop_ids).to_a if trip_stop_ids.any?

      place_lists = PlaceList.active.where(user: @user)
      place_list_ids = place_lists.pluck(:id).map(&:to_s)
      links.concat AssetLink.active.where(attachable_type: "PlaceList", attachable_id: place_list_ids).to_a if place_list_ids.any?

      place_list_item_ids = PlaceListItem.active.where(place_list_id: place_lists.select(:id)).pluck(:id).map(&:to_s)
      links.concat AssetLink.active.where(attachable_type: "PlaceListItem", attachable_id: place_list_item_ids).to_a if place_list_item_ids.any?

      favorite_place_ids = FavoritePlace.active.where(user: @user).pluck(:id).map(&:to_s)
      links.concat AssetLink.active.where(attachable_type: "FavoritePlace", attachable_id: favorite_place_ids).to_a if favorite_place_ids.any?

      drive_session_ids = DriveSession.active.where(user: @user).pluck(:id).map(&:to_s)
      links.concat AssetLink.active.where(attachable_type: "DriveSession", attachable_id: drive_session_ids).to_a if drive_session_ids.any?

      links.concat AssetLink.active.where(attachable_type: "Place", created_by_user: @user).to_a
      links.uniq(&:id)
    end

    def visible_assets_for(links)
      linked_asset_ids = links.map(&:asset_id)
      Asset.active.where(id: linked_asset_ids)
           .or(Asset.active.where(uploaded_by_user: @user))
           .to_a
    end
  end
end
