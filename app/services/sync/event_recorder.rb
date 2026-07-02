module Sync
  class EventRecorder
    def self.record!(record, action:, actor_user: nil, actor_device: nil, user: nil, trip: nil, metadata: {})
      SyncEvent.create!(
        entity_type: RecordSerializer.type_for(record),
        entity_id: record.id,
        trip: trip || RecordSerializer.trip_for(record),
        user: user || RecordSerializer.user_for(record),
        actor_user: actor_user,
        actor_device: actor_device,
        action: action,
        record_revision: record.respond_to?(:revision) ? record.revision : 1,
        occurred_at: Time.current,
        metadata: metadata || {}
      )
    end
  end
end
