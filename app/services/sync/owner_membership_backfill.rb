module Sync
  class OwnerMembershipBackfill
    Result = Struct.new(:created_memberships, :updated_memberships, :touched_trips, keyword_init: true)

    def self.call
      new.call
    end

    def call
      created_memberships = 0
      updated_memberships = 0
      touched_trips = 0

      Trip.active.includes(:owner_user).find_each do |trip|
        result = repair_trip_owner_membership(trip)
        next unless result

        created_memberships += 1 if result == :created
        updated_memberships += 1 if result == :updated
        touched_trips += 1
      end

      Result.new(
        created_memberships: created_memberships,
        updated_memberships: updated_memberships,
        touched_trips: touched_trips
      )
    end

    private

    def repair_trip_owner_membership(trip)
      owner = trip.owner_user
      member = TripMember.find_or_initialize_by(trip: trip, user: owner)
      was_new = member.new_record?

      member.role = "owner"
      member.status = "active"
      member.deleted_at = nil
      member.display_name = owner.display_name if member.display_name.blank?
      member.joined_at ||= trip.created_at || Time.current

      return unless was_new || member.changed?

      TripMember.transaction do
        member.revision = member.revision.to_i + 1 if member.persisted?
        member.save!
        EventRecorder.record!(
          member,
          action: was_new ? "created" : "updated",
          trip: trip,
          metadata: { repair: "owner_membership_backfill" }
        )
        EventRecorder.record!(
          trip,
          action: "updated",
          trip: trip,
          metadata: { repair: "owner_membership_backfill", trip_member_id: member.id }
        )
      end

      was_new ? :created : :updated
    end
  end
end
