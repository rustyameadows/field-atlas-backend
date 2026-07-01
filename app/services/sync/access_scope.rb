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

    def initialize(user:)
      @user = user
    end

    def active_trip_ids
      @active_trip_ids ||= TripMember.active.where(user: @user).select(:trip_id)
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

      false
    end

    def deleted_records
      DeletedRecord.where(user: @user).or(DeletedRecord.where(trip_id: active_trip_ids))
    end
  end
end
