class BackfillOwnerTripMembers < ActiveRecord::Migration[8.1]
  def up
    Sync::OwnerMembershipBackfill.call
  end

  def down
    # Data repair only. Owner memberships are authoritative after this migration.
  end
end
