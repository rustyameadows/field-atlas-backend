module Sync
  class Pull
    DEFAULT_LIMIT = 200
    MAX_LIMIT = 500

    def initialize(user:, cursor: nil, limit: nil, scope: nil)
      @user = user
      @cursor = cursor
      @limit = normalize_limit(limit)
      @scope = scope
      @access_scope = AccessScope.new(user: user)
    end

    def call
      after_id = Cursor.decode(@cursor)
      return initial_pull if after_id.zero?

      incremental_pull(after_id)
    end

    private

    def initial_pull
      max_event_id = SyncEvent.maximum(:id).to_i
      {
        changes: serialize_unique(@access_scope.visible_records),
        deleted_records: @access_scope.deleted_records.order(:deleted_at, :id).map { |record| Api::V1::Serializers.deleted_record(record) },
        next_cursor: Cursor.encode(max_event_id),
        has_more: false
      }
    end

    def incremental_pull(after_id)
      events = SyncEvent.where("id > ?", after_id).order(:id).limit(@limit + 1).to_a
      page = events.first(@limit)
      last_id = page.last&.id || after_id

      changes = []
      deleted = []
      page.each do |event|
        if event.action == "deleted" || event.action == "access_revoked"
          deleted.concat(deleted_records_for(event))
        else
          record = @access_scope.visible_record(event.entity_type, event.entity_id)
          changes << record if record
        end
      end

      {
        changes: serialize_unique(changes),
        deleted_records: deleted.uniq(&:id).map { |record| Api::V1::Serializers.deleted_record(record) },
        next_cursor: Cursor.encode(last_id),
        has_more: events.length > @limit
      }
    end

    def deleted_records_for(event)
      DeletedRecord.where(entity_type: event.entity_type, entity_id: event.entity_id)
                   .select { |record| record.user_id == @user.id || @access_scope.active_trip?(record.trip_id) }
    end

    def serialize_unique(records)
      records.compact.uniq { |record| [ record.class.name, record.id ] }.map { |record| RecordSerializer.serialize(record) }
    end

    def normalize_limit(limit)
      value = limit.to_i
      value = DEFAULT_LIMIT if value <= 0
      [ value, MAX_LIMIT ].min
    end
  end
end
