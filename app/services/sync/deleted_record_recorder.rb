module Sync
  class DeletedRecordRecorder
    def self.record!(entity_type:, entity_id:, trip: nil, user: nil, deleted_by_user: nil, deleted_by_device: nil, reason: "deleted", revision: 1, metadata: {})
      deleted_record = DeletedRecord.create!(
        entity_type: entity_type,
        entity_id: entity_id,
        trip: trip,
        user: user,
        deleted_at: Time.current,
        revision: revision,
        deleted_by_user: deleted_by_user,
        deleted_by_device: deleted_by_device,
        reason: reason,
        metadata: metadata || {}
      )

      SyncEvent.create!(
        entity_type: entity_type,
        entity_id: entity_id,
        trip: trip,
        user: user,
        actor_user: deleted_by_user,
        actor_device: deleted_by_device,
        action: reason == "access_revoked" ? "access_revoked" : "deleted",
        record_revision: revision,
        occurred_at: deleted_record.deleted_at,
        metadata: metadata || {}
      )

      deleted_record
    end
  end
end
