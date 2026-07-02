require "test_helper"

class Sync::OwnerMembershipBackfillTest < ActiveSupport::TestCase
  test "creates missing owner memberships and emits member and trip sync events" do
    user = create_user(email: "owner-backfill@example.com", display_name: "Owner Field")
    trip = Trip.create!(owner_user: user, title: "Legacy Owner Trip")

    result = Sync::OwnerMembershipBackfill.call

    member = TripMember.find_by!(trip: trip, user: user)
    assert_equal "owner", member.role
    assert_equal "active", member.status
    assert_nil member.deleted_at
    assert_equal "Owner Field", member.display_name

    assert_equal 1, result.created_memberships
    assert_equal 0, result.updated_memberships
    assert_equal 1, result.touched_trips
    assert SyncEvent.where(entity_type: "trip_member", entity_id: member.id, action: "created", trip: trip).exists?
    assert SyncEvent.where(entity_type: "trip", entity_id: trip.id, action: "updated", trip: trip).exists?
  end

  test "restores inactive owner memberships and is idempotent once repaired" do
    user = create_user(email: "inactive-owner@example.com")
    trip = Trip.create!(owner_user: user, title: "Inactive Owner Member Trip")
    member = TripMember.create!(
      trip: trip,
      user: user,
      role: "viewer",
      status: "removed",
      deleted_at: 1.day.ago,
      joined_at: 2.days.ago
    )

    first_result = Sync::OwnerMembershipBackfill.call

    member.reload
    assert_equal "owner", member.role
    assert_equal "active", member.status
    assert_nil member.deleted_at
    assert_equal 0, first_result.created_memberships
    assert_equal 1, first_result.updated_memberships
    assert_equal 1, first_result.touched_trips

    event_count = SyncEvent.count
    second_result = Sync::OwnerMembershipBackfill.call

    assert_equal 0, second_result.created_memberships
    assert_equal 0, second_result.updated_memberships
    assert_equal 0, second_result.touched_trips
    assert_equal event_count, SyncEvent.count
  end

  private

  def create_user(email:, display_name: "Owner Field")
    User.create!(
      email: email,
      display_name: display_name,
      email_verified: true,
      status: "active"
    )
  end
end
