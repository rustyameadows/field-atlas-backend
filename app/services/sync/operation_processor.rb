module Sync
  class OperationProcessor
    MISSING = Object.new.freeze
    UUID_PATTERN = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i

    GENERIC_UPSERTS = {
      "upsert_favorite_place" => {
        model: FavoritePlace,
        owner: :user,
        fields: {
          place_id: %i[place_id placeID],
          name: %i[name],
          favorited_at: %i[favorited_at favoritedAt],
          encoded_place: %i[encoded_place encodedPlace]
        }
      },
      "upsert_place_list" => {
        model: PlaceList,
        owner: :user,
        fields: {
          name: %i[name title],
          marker_shape: %i[marker_shape markerShape],
          marker_color_red: %i[marker_color_red markerColorRed],
          marker_color_green: %i[marker_color_green markerColorGreen],
          marker_color_blue: %i[marker_color_blue markerColorBlue]
        }
      },
      "record_search_history_entry" => {
        model: SearchHistoryEntry,
        owner: :user,
        fields: {
          query: %i[query],
          searched_at: %i[searched_at searchedAt],
          latitude: %i[latitude],
          longitude: %i[longitude],
          encoded_entry: %i[encoded_entry encodedEntry]
        }
      },
      "upsert_search_session" => {
        model: SearchSession,
        owner: :user,
        fields: {
          query: %i[query],
          encoded_session: %i[encoded_session encodedSession]
        }
      },
      "upsert_search_result_snapshot" => {
        model: SearchResultSnapshot,
        owner: :search_session,
        fields: {
          place_id: %i[place_id placeID],
          sort_key: %i[sort_key sortKey],
          encoded_place: %i[encoded_place encodedPlace]
        }
      },
      "create_memory_asset" => {
        model: MemoryAsset,
        owner: :user,
        fields: {
          kind: %i[kind],
          title: %i[title],
          local_file_name: %i[local_file_name localFileName],
          transcript: %i[transcript],
          transcript_status: %i[transcript_status transcriptStatus],
          encoded_asset: %i[encoded_asset encodedAsset]
        }
      },
      "update_memory_asset" => {
        model: MemoryAsset,
        owner: :user,
        fields: {
          kind: %i[kind],
          title: %i[title],
          local_file_name: %i[local_file_name localFileName],
          transcript: %i[transcript],
          transcript_status: %i[transcript_status transcriptStatus],
          encoded_asset: %i[encoded_asset encodedAsset]
        }
      },
      "create_drive_session" => {
        model: DriveSession,
        owner: :user,
        fields: {
          started_at: %i[started_at startedAt],
          ended_at: %i[ended_at endedAt],
          encoded_session: %i[encoded_session encodedSession]
        }
      },
      "update_drive_session" => {
        model: DriveSession,
        owner: :user,
        fields: {
          started_at: %i[started_at startedAt],
          ended_at: %i[ended_at endedAt],
          encoded_session: %i[encoded_session encodedSession]
        }
      },
      "end_drive_session" => {
        model: DriveSession,
        owner: :user,
        fields: {
          ended_at: %i[ended_at endedAt],
          encoded_session: %i[encoded_session encodedSession]
        }
      }
    }.freeze

    GENERIC_DELETES = {
      "delete_favorite_place" => FavoritePlace,
      "delete_place_list" => PlaceList,
      "delete_place_list_item" => PlaceListItem,
      "delete_search_session" => SearchSession,
      "delete_memory_asset" => MemoryAsset,
      "delete_drive_session" => DriveSession
    }.freeze

    def initialize(user:, device:, operations:)
      @user = user
      @current_device = device
      @operations = Array(operations)
    end

    def call
      {
        results: @operations.map { |operation| process_operation(operation) }
      }
    end

    private

    def process_operation(raw_operation)
      operation = raw_operation.to_h.with_indifferent_access
      wrapper_error = validate_wrapper(operation)
      return rejected_result(operation, "invalid_operation", wrapper_error) if wrapper_error

      device = resolve_device(operation)
      return rejected_result(operation, "invalid_device", "Device is required and must belong to the authenticated user.") if device.blank?

      existing = ClientOperation.find_by(device: device, operation_id: operation[:operation_id])
      return existing.result if existing&.processed_at?

      result = nil
      ActiveRecord::Base.transaction do
        client_operation = existing || ClientOperation.create!(client_operation_attributes(operation, device))
        result = dispatch(operation, device)
        client_operation.update!(
          status: result[:status],
          result: result,
          error_code: result.dig(:error, :code),
          message: result.dig(:error, :message),
          processed_at: Time.current
        )
      end
      result
    rescue ActiveRecord::RecordInvalid => e
      persist_failure(operation, device, rejected_result(operation, "validation_failed", e.record.errors.full_messages.to_sentence))
    rescue ActiveRecord::RecordNotFound => e
      persist_failure(operation, device, rejected_result(operation, "not_found", e.message))
    end

    def validate_wrapper(operation)
      %i[operation_id entity_type entity_id action].each do |key|
        return "#{key} is required" if operation[key].blank?
      end
      nil
    end

    def resolve_device(operation)
      device_id = operation[:device_id].presence
      return @current_device if device_id.blank? && @current_device&.user_id == @user.id

      Device.active.find_by(id: device_id, user: @user)
    end

    def client_operation_attributes(operation, device)
      {
        operation_id: operation[:operation_id],
        device: device,
        user: @user,
        entity_type: operation[:entity_type],
        entity_id: operation[:entity_id],
        action: operation[:action],
        payload: preserve_payload(operation[:payload]),
        base_revision: operation[:base_revision],
        client_created_at: parse_time(operation[:created_at]),
        received_at: Time.current
      }
    end

    def persist_failure(operation, device, result)
      return result if device.blank?

      ClientOperation.transaction do
        client_operation = ClientOperation.find_or_initialize_by(device: device, operation_id: operation[:operation_id])
        client_operation.assign_attributes(client_operation_attributes(operation, device)) if client_operation.new_record?
        client_operation.update!(
          status: result[:status],
          result: result,
          error_code: result.dig(:error, :code),
          message: result.dig(:error, :message),
          processed_at: Time.current
        )
      end
      result
    end

    def dispatch(operation, device)
      case operation[:action]
      when "upsert_trip_workspace"
        upsert_trip_workspace(operation, device)
      when "create_trip"
        upsert_trip_workspace(operation, device)
      when "rename_trip", "update_trip", "update_trip_dates"
        update_trip(operation, device)
      when "delete_trip"
        delete_trip(operation, device)
      when "create_or_update_segment", "update_segment"
        upsert_segment(operation, device)
      when "delete_segment"
        delete_segment(operation, device)
      when "add_stop", "update_stop", "move_stop", "add_route_waypoint", "update_stop_kind"
        upsert_stop(operation, device)
      when "remove_stop", "remove_route_waypoint"
        delete_stop(operation, device)
      when "upsert_option_link"
        upsert_option_link(operation, device)
      when "delete_option_link"
        delete_option_link(operation, device)
      when "save_route_snapshot"
        save_route_snapshot(operation, device)
      when "delete_route_snapshot"
        delete_route_snapshot(operation, device)
      when "upsert_place_list_item"
        upsert_place_list_item(operation, device)
      when "upsert_user_setting"
        upsert_user_setting(operation, device)
      when "create_trip_invite", "accept_trip_invite", "revoke_trip_invite", "remove_trip_member", "update_trip_member_role"
        collaboration_operation(operation, device)
      else
        if GENERIC_UPSERTS.key?(operation[:action])
          upsert_generic_user_data(operation, device, GENERIC_UPSERTS.fetch(operation[:action]))
        elsif GENERIC_DELETES.key?(operation[:action])
          delete_generic_user_data(operation, device, GENERIC_DELETES.fetch(operation[:action]))
        else
          rejected_result(operation, "unsupported_action", "Unsupported operation action: #{operation[:action]}")
        end
      end
    end

    def upsert_trip_workspace(operation, device)
      payload = payload_hash(operation)
      local_id = local_id_from(payload, operation)
      trip = find_trip_for_upsert(local_id, operation)
      was_new = trip.new_record?

      unless was_new || trip.editable_by?(@user)
        return rejected_result(operation, "forbidden", "You do not have permission to edit this trip.")
      end

      trip.owner_user ||= @user
      trip.created_by_device ||= device
      trip.client_id ||= local_id
      assign_value(trip, :title, payload, :title, default: "Untitled Trip")
      assign_value(trip, :start_date, payload, :start_date, :startDate)
      assign_value(trip, :end_date, payload, :end_date, :endDate)
      assign_value(trip, :encoded_workspace, payload, :encoded_workspace, :encodedWorkspace)
      trip.client_payload = payload.to_h
      save_with_event!(trip, action_for(was_new), actor_device: device, actor_user: @user)

      owner_member = TripMember.find_or_initialize_by(trip: trip, user: @user)
      if owner_member.new_record?
        owner_member.role = "owner"
        owner_member.status = "active"
        owner_member.display_name = @user.display_name
        save_with_event!(owner_member, "created", actor_device: device, actor_user: @user, trip: trip)
      end

      mappings = [ mapping("trip", local_id, trip) ]
      segment_map = upsert_workspace_segments(trip, payload, device, mappings)
      stop_map = upsert_workspace_stops(trip, payload, device, mappings, segment_map)
      upsert_workspace_option_links(trip, payload, device, mappings, stop_map)
      upsert_workspace_route_snapshots(trip, payload, device, mappings, segment_map, stop_map)

      accepted_result(operation, server_id: trip.id, revision: trip.revision, mappings: mappings)
    end

    def update_trip(operation, device)
      payload = payload_hash(operation)
      trip = find_accessible_trip(operation[:entity_id], payload)
      return rejected_result(operation, "forbidden", "You do not have permission to edit this trip.") unless trip.editable_by?(@user)
      conflict = conflict_if_stale(operation, trip)
      return conflict if conflict

      assign_value(trip, :title, payload, :title) if operation[:action] == "rename_trip" || payload.key?(:title)
      assign_value(trip, :start_date, payload, :start_date, :startDate)
      assign_value(trip, :end_date, payload, :end_date, :endDate)
      trip.client_payload = trip.client_payload.merge(payload.to_h)
      save_with_event!(trip, "updated", actor_device: device, actor_user: @user)
      accepted_result(operation, server_id: trip.id, revision: trip.revision, mappings: [ mapping("trip", operation[:entity_id], trip) ])
    end

    def delete_trip(operation, device)
      trip = find_accessible_trip(operation[:entity_id], payload_hash(operation))
      return rejected_result(operation, "forbidden", "You do not have permission to delete this trip.") unless trip.manageable_by?(@user)
      conflict = conflict_if_stale(operation, trip)
      return conflict if conflict

      soft_delete!(trip, device: device, reason: "deleted")
      accepted_result(operation, server_id: trip.id, revision: trip.revision)
    end

    def upsert_segment(operation, device)
      payload = payload_hash(operation)
      trip = find_accessible_trip(trip_identifier_from(payload, operation), payload)
      return rejected_result(operation, "forbidden", "You do not have permission to edit this trip.") unless trip.editable_by?(@user)

      segment = find_child(trip.segments, local_id_from(payload, operation))
      was_new = segment.new_record?
      assign_segment(segment, payload)
      save_with_event!(segment, action_for(was_new), actor_device: device, actor_user: @user, trip: trip)
      accepted_result(operation, server_id: segment.id, revision: segment.revision, mappings: [ mapping("trip_segment", segment.client_id || operation[:entity_id], segment) ])
    end

    def delete_segment(operation, device)
      segment = find_record_by_local_or_server(TripSegment, operation[:entity_id])
      return rejected_result(operation, "forbidden", "You do not have permission to edit this trip.") unless segment.trip.editable_by?(@user)

      soft_delete!(segment, device: device, reason: "deleted")
      accepted_result(operation, server_id: segment.id, revision: segment.revision)
    end

    def upsert_stop(operation, device)
      payload = payload_hash(operation)
      payload[:kind] = "waypoint" if operation[:action] == "add_route_waypoint" && !payload.key?(:kind)
      trip = find_accessible_trip(trip_identifier_from(payload, operation), payload)
      return rejected_result(operation, "forbidden", "You do not have permission to edit this trip.") unless trip.editable_by?(@user)

      segment_map = trip.segments.index_by(&:client_id)
      stop = find_child(trip.stops, local_id_from(payload, operation))
      was_new = stop.new_record?
      assign_stop(stop, payload, segment_map, device)
      save_with_event!(stop, action_for(was_new), actor_device: device, actor_user: @user, trip: trip)
      accepted_result(operation, server_id: stop.id, revision: stop.revision, mappings: [ mapping("trip_stop", stop.client_id || operation[:entity_id], stop) ])
    end

    def delete_stop(operation, device)
      stop = find_record_by_local_or_server(TripStop, operation[:entity_id])
      return rejected_result(operation, "forbidden", "You do not have permission to edit this trip.") unless stop.trip.editable_by?(@user)

      soft_delete!(stop, device: device, reason: "deleted")
      accepted_result(operation, server_id: stop.id, revision: stop.revision)
    end

    def upsert_option_link(operation, device)
      payload = payload_hash(operation)
      trip = find_accessible_trip(trip_identifier_from(payload, operation), payload)
      return rejected_result(operation, "forbidden", "You do not have permission to edit this trip.") unless trip.editable_by?(@user)

      stop_map = trip.stops.index_by(&:client_id)
      link = find_child(trip.option_links, local_id_from(payload, operation))
      was_new = link.new_record?
      assign_option_link(link, payload, stop_map)
      save_with_event!(link, action_for(was_new), actor_device: device, actor_user: @user, trip: trip)
      accepted_result(operation, server_id: link.id, revision: link.revision, mappings: [ mapping("trip_stop_option_link", link.client_id || operation[:entity_id], link) ])
    end

    def delete_option_link(operation, device)
      link = find_record_by_local_or_server(TripStopOptionLink, operation[:entity_id])
      return rejected_result(operation, "forbidden", "You do not have permission to edit this trip.") unless link.trip.editable_by?(@user)

      soft_delete!(link, device: device, reason: "deleted")
      accepted_result(operation, server_id: link.id, revision: link.revision)
    end

    def save_route_snapshot(operation, device)
      payload = payload_hash(operation)
      trip = find_accessible_trip(trip_identifier_from(payload, operation), payload)
      return rejected_result(operation, "forbidden", "You do not have permission to edit this trip.") unless trip.editable_by?(@user)

      mappings = []
      segment_map = trip.segments.index_by(&:client_id)
      stop_map = trip.stops.index_by(&:client_id)
      snapshot = persist_route_snapshot(trip, payload, device, mappings, segment_map, stop_map, operation)
      accepted_result(operation, server_id: snapshot.id, revision: snapshot.revision, mappings: mappings)
    end

    def delete_route_snapshot(operation, device)
      snapshot = find_record_by_local_or_server(RouteSnapshot, operation[:entity_id])
      return rejected_result(operation, "forbidden", "You do not have permission to edit this trip.") unless snapshot.trip.editable_by?(@user)

      soft_delete!(snapshot, device: device, reason: "deleted")
      accepted_result(operation, server_id: snapshot.id, revision: snapshot.revision)
    end

    def upsert_workspace_segments(trip, payload, device, mappings)
      segment_map = {}
      seen_ids = []
      array_payload(payload, :segments).each do |segment_payload|
        segment_payload = segment_payload.with_indifferent_access
        segment = find_child(trip.segments, local_id_from(segment_payload, nil))
        was_new = segment.new_record?
        assign_segment(segment, segment_payload)
        save_with_event!(segment, action_for(was_new), actor_device: device, actor_user: @user, trip: trip)
        segment_map[segment.client_id] = segment if segment.client_id.present?
        seen_ids << segment.client_id if segment.client_id.present?
        mappings << mapping("trip_segment", segment.client_id, segment)
      end
      tombstone_missing_children(trip.segments.active, seen_ids, device) if payload_has_any?(payload, :segments)
      segment_map
    end

    def upsert_workspace_stops(trip, payload, device, mappings, segment_map)
      stop_map = {}
      seen_ids = []
      array_payload(payload, :stops).each do |stop_payload|
        stop_payload = stop_payload.with_indifferent_access
        stop = find_child(trip.stops, local_id_from(stop_payload, nil))
        was_new = stop.new_record?
        assign_stop(stop, stop_payload, segment_map, device)
        save_with_event!(stop, action_for(was_new), actor_device: device, actor_user: @user, trip: trip)
        stop_map[stop.client_id] = stop if stop.client_id.present?
        seen_ids << stop.client_id if stop.client_id.present?
        mappings << mapping("trip_stop", stop.client_id, stop)
      end
      tombstone_missing_children(trip.stops.active, seen_ids, device) if payload_has_any?(payload, :stops)
      stop_map
    end

    def upsert_workspace_option_links(trip, payload, device, mappings, stop_map)
      seen_ids = []
      array_payload(payload, :optionLinks, :option_links).each do |link_payload|
        link_payload = link_payload.with_indifferent_access
        link = find_child(trip.option_links, local_id_from(link_payload, nil))
        was_new = link.new_record?
        assign_option_link(link, link_payload, stop_map)
        save_with_event!(link, action_for(was_new), actor_device: device, actor_user: @user, trip: trip)
        seen_ids << link.client_id if link.client_id.present?
        mappings << mapping("trip_stop_option_link", link.client_id, link)
      end
      tombstone_missing_children(trip.option_links.active, seen_ids, device) if payload_has_any?(payload, :optionLinks, :option_links)
    end

    def upsert_workspace_route_snapshots(trip, payload, device, mappings, segment_map, stop_map)
      array_payload(payload, :routeSnapshots, :route_snapshots).each do |snapshot_payload|
        persist_route_snapshot(trip, snapshot_payload.with_indifferent_access, device, mappings, segment_map, stop_map, nil)
      end
    end

    def assign_segment(segment, payload)
      segment.trip ||= Trip.find(read_payload(payload, :trip_id, :tripID)) if segment.trip.blank? && read_payload(payload, :trip_id, :tripID) != MISSING
      segment.client_id ||= local_id_from(payload, nil)
      assign_value(segment, :title, payload, :title, :name, default: "Untitled Segment")
      assign_value(segment, :container_type, payload, :container_type, :containerType)
      assign_value(segment, :segment_kind, payload, :segment_kind, :segmentKind)
      assign_value(segment, :auto_day_index, payload, :auto_day_index, :autoDayIndex)
      assign_value(segment, :start_date, payload, :start_date, :startDate)
      assign_value(segment, :end_date, payload, :end_date, :endDate)
      assign_value(segment, :sort_key, payload, :sort_key, :sortKey, default: 0)
      assign_value(segment, :color_token_id, payload, :color_token_id, :colorTokenID, :colorTokenId)
      assign_value(segment, :encoded_segment, payload, :encoded_segment, :encodedSegment)
      segment.client_payload = payload.to_h
    end

    def assign_stop(stop, payload, segment_map, device)
      stop.client_id ||= local_id_from(payload, nil)
      stop.created_by_user ||= @user
      stop.created_by_device ||= device
      segment_identifier = read_payload(payload, :segment_id, :segmentID, :trip_segment_id, :tripSegmentID)
      stop.segment = segment_for_identifier(segment_identifier, segment_map) unless segment_identifier == MISSING
      assign_value(stop, :item_id, payload, :item_id, :itemID)
      assign_value(stop, :placement_id, payload, :placement_id, :placementID)
      assign_value(stop, :kind, payload, :kind, default: "idea")
      assign_value(stop, :title, payload, :title, :name, default: "Untitled Stop")
      assign_value(stop, :subtitle, payload, :subtitle)
      assign_value(stop, :notes, payload, :notes)
      assign_value(stop, :sort_key, payload, :sort_key, :sortKey, default: 0)
      assign_value(stop, :place_title, payload, :place_title, :placeTitle)
      assign_value(stop, :place_subtitle, payload, :place_subtitle, :placeSubtitle)
      assign_value(stop, :address, payload, :address)
      assign_value(stop, :latitude, payload, :latitude)
      assign_value(stop, :longitude, payload, :longitude)
      assign_value(stop, :source, payload, :source)
      assign_value(stop, :source_identifier, payload, :source_identifier, :sourceIdentifier)
      assign_value(stop, :provider, payload, :provider)
      assign_value(stop, :provider_id, payload, :provider_id, :providerID)
      assign_value(stop, :source_ids, payload, :source_ids, :sourceIDs, :sourceIds)
      assign_value(stop, :location_target, payload, :location_target, :locationTarget)
      assign_value(stop, :encoded_item, payload, :encoded_item, :encodedItem)
      assign_value(stop, :encoded_placement, payload, :encoded_placement, :encodedPlacement)
      canonical_place_id = read_payload(payload, :canonical_place_id, :canonicalPlaceID, :canonicalPlaceId)
      stop.canonical_place_id = canonical_place_id unless canonical_place_id == MISSING
      stop.client_payload = payload.to_h
    end

    def assign_option_link(link, payload, stop_map)
      link.client_id ||= local_id_from(payload, nil)
      assign_value(link, :group_id, payload, :group_id, :groupID, default: "default")
      parent_identifier = read_payload(payload, :parent_stop_id, :parentStopID, :parentStopId)
      candidate_identifier = read_payload(payload, :candidate_stop_id, :candidateStopID, :candidateStopId)
      link.parent_stop = stop_for_identifier(parent_identifier, stop_map) unless parent_identifier == MISSING
      link.candidate_stop = stop_for_identifier(candidate_identifier, stop_map) unless candidate_identifier == MISSING
      assign_value(link, :group_title, payload, :group_title, :groupTitle)
      assign_value(link, :role, payload, :role)
      assign_value(link, :status, payload, :status)
      assign_value(link, :is_selected, payload, :is_selected, :isSelected, default: false)
      assign_value(link, :sort_key, payload, :sort_key, :sortKey, default: 0)
      link.client_payload = payload.to_h
    end

    def persist_route_snapshot(trip, payload, device, mappings, segment_map, stop_map, operation)
      snapshot = find_child(trip.route_snapshots, local_id_from(payload, operation))
      was_new = snapshot.new_record?
      snapshot.created_by_user ||= @user
      snapshot.created_by_device ||= device
      segment_identifier = read_payload(payload, :segment_id, :segmentID, :trip_segment_id, :tripSegmentID)
      snapshot.trip_segment = segment_for_identifier(segment_identifier, segment_map) unless segment_identifier == MISSING
      snapshot.client_id ||= local_id_from(payload, operation)
      assign_value(snapshot, :provider, payload, :provider, default: "apple-mapkit")
      assign_value(snapshot, :stale, payload, :stale, default: false)
      assign_value(snapshot, :total_distance_meters, payload, :total_distance_meters, :totalDistanceMeters, default: 0)
      assign_value(snapshot, :expected_travel_time, payload, :expected_travel_time, :expectedTravelTime, default: 0)
      assign_value(snapshot, :routing_signature, payload, :routing_signature, :routingSignature)
      assign_value(snapshot, :encoded_route, payload, :encoded_route, :encodedRoute)
      snapshot.client_payload = payload.to_h
      save_with_event!(snapshot, action_for(was_new), actor_device: device, actor_user: @user, trip: trip)
      mappings << mapping("route_snapshot", snapshot.client_id, snapshot)

      persist_route_snapshot_stops(snapshot, payload, device, mappings, stop_map)
      persist_route_legs(snapshot, payload, device, mappings, stop_map)
      snapshot
    end

    def persist_route_snapshot_stops(snapshot, payload, device, mappings, stop_map)
      array_payload(payload, :snapshotStops, :snapshot_stops, :stops).each do |stop_payload|
        stop_payload = stop_payload.with_indifferent_access
        child = find_child(snapshot.snapshot_stops, local_id_from(stop_payload, nil))
        was_new = child.new_record?
        child.client_id ||= local_id_from(stop_payload, nil)
        trip_stop_identifier = read_payload(stop_payload, :trip_stop_id, :tripStopID, :tripStopId)
        child.trip_stop = stop_for_identifier(trip_stop_identifier, stop_map) unless trip_stop_identifier == MISSING
        assign_value(child, :kind, stop_payload, :kind, default: "route_stop")
        assign_value(child, :sort_key, stop_payload, :sort_key, :sortKey, default: 0)
        assign_value(child, :latitude, stop_payload, :latitude)
        assign_value(child, :longitude, stop_payload, :longitude)
        assign_value(child, :title, stop_payload, :title, default: "Route Stop")
        save_with_event!(child, action_for(was_new), actor_device: device, actor_user: @user, trip: snapshot.trip)
        mappings << mapping("route_snapshot_stop", child.client_id, child)
      end
    end

    def persist_route_legs(snapshot, payload, device, mappings, stop_map)
      array_payload(payload, :legs).each do |leg_payload|
        leg_payload = leg_payload.with_indifferent_access
        leg = find_child(snapshot.legs, local_id_from(leg_payload, nil))
        was_new = leg.new_record?
        leg.client_id ||= local_id_from(leg_payload, nil)
        source_identifier = read_payload(leg_payload, :source_stop_id, :sourceStopID, :sourceStopId)
        destination_identifier = read_payload(leg_payload, :destination_stop_id, :destinationStopID, :destinationStopId)
        leg.source_stop = stop_for_identifier(source_identifier, stop_map) unless source_identifier == MISSING
        leg.destination_stop = stop_for_identifier(destination_identifier, stop_map) unless destination_identifier == MISSING
        assign_value(leg, :name, leg_payload, :name)
        assign_value(leg, :label, leg_payload, :label)
        assign_value(leg, :distance_meters, leg_payload, :distance_meters, :distanceMeters, default: 0)
        assign_value(leg, :expected_travel_time, leg_payload, :expected_travel_time, :expectedTravelTime, default: 0)
        assign_value(leg, :sort_key, leg_payload, :sort_key, :sortKey, default: 0)
        assign_value(leg, :encoded_polyline, leg_payload, :encoded_polyline, :encodedPolyline)
        save_with_event!(leg, action_for(was_new), actor_device: device, actor_user: @user, trip: snapshot.trip)
        mappings << mapping("route_leg", leg.client_id, leg)
        persist_route_steps(leg, leg_payload, device, mappings, snapshot.trip)
      end
    end

    def persist_route_steps(leg, leg_payload, device, mappings, trip)
      array_payload(leg_payload, :steps).each do |step_payload|
        step_payload = step_payload.with_indifferent_access
        step = find_child(leg.steps, local_id_from(step_payload, nil))
        was_new = step.new_record?
        step.client_id ||= local_id_from(step_payload, nil)
        assign_value(step, :instructions, step_payload, :instructions, default: "")
        assign_value(step, :notice, step_payload, :notice)
        assign_value(step, :distance_meters, step_payload, :distance_meters, :distanceMeters, default: 0)
        assign_value(step, :transport_type, step_payload, :transport_type, :transportType)
        assign_value(step, :sort_key, step_payload, :sort_key, :sortKey, default: 0)
        assign_value(step, :encoded_polyline, step_payload, :encoded_polyline, :encodedPolyline)
        save_with_event!(step, action_for(was_new), actor_device: device, actor_user: @user, trip: trip)
        mappings << mapping("route_step", step.client_id, step)
      end
    end

    def upsert_place_list_item(operation, device)
      payload = payload_hash(operation)
      list_identifier = read_payload(payload, :place_list_id, :placeListID, :placeListId)
      list = find_user_place_list(list_identifier)
      return rejected_result(operation, "not_found", "Place list was not found.") if list.blank?

      item = find_child(list.items, local_id_from(payload, operation))
      was_new = item.new_record?
      item.client_id ||= local_id_from(payload, operation)
      assign_value(item, :place_id, payload, :place_id, :placeID)
      assign_value(item, :sort_key, payload, :sort_key, :sortKey, default: 0)
      assign_value(item, :added_at, payload, :added_at, :addedAt)
      assign_value(item, :encoded_place, payload, :encoded_place, :encodedPlace)
      item.client_payload = payload.to_h
      save_with_event!(item, action_for(was_new), actor_device: device, actor_user: @user)
      accepted_result(operation, server_id: item.id, revision: item.revision, mappings: [ mapping("place_list_item", item.client_id, item) ])
    end

    def upsert_user_setting(operation, device)
      payload = payload_hash(operation)
      key = read_payload(payload, :key)
      return rejected_result(operation, "invalid_payload", "key is required for user settings.") if key == MISSING || key.blank?

      setting = UserSetting.find_or_initialize_by(user: @user, key: key)
      was_new = setting.new_record?
      assign_value(setting, :value, payload, :value)
      save_with_event!(setting, action_for(was_new), actor_device: device, actor_user: @user)
      accepted_result(operation, server_id: setting.id, revision: setting.revision, mappings: [ mapping("user_setting", key, setting) ])
    end

    def upsert_generic_user_data(operation, device, config)
      payload = payload_hash(operation)
      model = config.fetch(:model)
      record = find_generic_record(model, payload, operation, config.fetch(:owner))
      was_new = record.new_record?
      assign_generic_owner(record, payload, config.fetch(:owner))
      record.client_id ||= local_id_from(payload, operation) if record.respond_to?(:client_id)
      config.fetch(:fields).each do |attribute, keys|
        assign_value(record, attribute, payload, *keys)
      end
      record.client_payload = payload.to_h if record.respond_to?(:client_payload=)
      save_with_event!(record, action_for(was_new), actor_device: device, actor_user: @user, trip: RecordSerializer.trip_for(record))
      accepted_result(operation, server_id: record.id, revision: record.revision, mappings: [ mapping(RecordSerializer.type_for(record), record.respond_to?(:client_id) ? record.client_id : operation[:entity_id], record) ])
    end

    def delete_generic_user_data(operation, device, model)
      record = find_record_by_local_or_server(model, operation[:entity_id])
      return rejected_result(operation, "forbidden", "You do not have permission to delete this record.") unless AccessScope.new(user: @user).visible?(record)

      soft_delete!(record, device: device, reason: "deleted")
      accepted_result(operation, server_id: record.id, revision: record.revision)
    end

    def collaboration_operation(operation, device)
      case operation[:action]
      when "create_trip_invite"
        payload = payload_hash(operation)
        trip = find_accessible_trip(trip_identifier_from(payload, operation), payload)
        return rejected_result(operation, "forbidden", "You do not have permission to invite members.") unless trip.manageable_by?(@user)

        invite = TripInvite.create!(
          trip: trip,
          invited_by_user: @user,
          role: read_payload(payload, :role) == MISSING ? "editor" : read_payload(payload, :role),
          expires_at: seconds_from_now(read_payload(payload, :expires_in_seconds, :expiresInSeconds))
        )
        EventRecorder.record!(invite, action: "created", actor_user: @user, actor_device: device, trip: trip)
        accepted_result(operation, server_id: invite.id, revision: invite.revision, mappings: [ mapping("trip_invite", invite.token, invite) ])
      when "accept_trip_invite"
        invite = find_invite_for_operation(operation)
        return rejected_result(operation, "invalid_invite", "Invite is not pending.") unless invite.pending?

        member = TripMember.find_or_initialize_by(trip: invite.trip, user: @user)
        was_new = member.new_record?
        member.role = invite.role
        member.status = "active"
        member.deleted_at = nil
        member.display_name = @user.display_name
        member.joined_at ||= Time.current
        member.revision += 1 if member.persisted? && member.changed?
        member.save!
        invite.accept!(@user)
        EventRecorder.record!(member, action: action_for(was_new), actor_user: @user, actor_device: device, trip: invite.trip)
        EventRecorder.record!(invite, action: "updated", actor_user: @user, actor_device: device, trip: invite.trip)
        accepted_result(operation, server_id: member.id, revision: member.revision, mappings: [ mapping("trip_member", member.id, member) ])
      when "revoke_trip_invite"
        invite = find_invite_for_operation(operation)
        return rejected_result(operation, "forbidden", "You do not have permission to revoke this invite.") unless invite.trip.manageable_by?(@user)

        invite.update!(status: "revoked", deleted_at: Time.current, revision: invite.revision + 1)
        EventRecorder.record!(invite, action: "updated", actor_user: @user, actor_device: device, trip: invite.trip)
        accepted_result(operation, server_id: invite.id, revision: invite.revision)
      when "remove_trip_member"
        member = find_member_for_operation(operation)
        return rejected_result(operation, "forbidden", "You do not have permission to remove this member.") unless member.trip.manageable_by?(@user)
        return rejected_result(operation, "invalid_member_removal", "Cannot remove the last active owner.") if member.owner? && member.trip.members.active.where(role: "owner").count <= 1

        member.remove!
        EventRecorder.record!(member, action: "updated", actor_user: @user, actor_device: device, trip: member.trip)
        DeletedRecordRecorder.record!(
          entity_type: "trip",
          entity_id: member.trip_id,
          trip: member.trip,
          user: member.user,
          deleted_by_user: @user,
          deleted_by_device: device,
          reason: "access_revoked",
          revision: member.trip.revision
        )
        accepted_result(operation, server_id: member.id, revision: member.revision)
      when "update_trip_member_role"
        payload = payload_hash(operation)
        member = find_member_for_operation(operation)
        role = read_payload(payload, :role)
        return rejected_result(operation, "invalid_member_role", "role is required.") if role == MISSING
        return rejected_result(operation, "forbidden", "You do not have permission to update this member.") unless member.trip.manageable_by?(@user)
        return rejected_result(operation, "invalid_member_role", "Cannot remove the last active owner.") if member.owner? && role != "owner" && member.trip.members.active.where(role: "owner").count <= 1

        member.update!(role: role, revision: member.revision + 1)
        EventRecorder.record!(member, action: "updated", actor_user: @user, actor_device: device, trip: member.trip)
        accepted_result(operation, server_id: member.id, revision: member.revision)
      else
        rejected_result(operation, "use_rest_endpoint", "#{operation[:action]} is available through the collaboration REST endpoints.")
      end
    end

    def find_trip_for_upsert(local_id, operation)
      trip = if uuid?(operation[:entity_id])
        Trip.find_by(id: operation[:entity_id])
      end
      trip ||= accessible_trip_scope.find_by(client_id: local_id)
      trip || Trip.new
    end

    def find_accessible_trip(identifier, payload)
      raise ActiveRecord::RecordNotFound if identifier == MISSING || identifier.blank?

      trip = if uuid?(identifier)
        Trip.find(identifier)
      else
        local_id = read_payload(payload, :trip_id, :tripID, :id, :client_id, :clientID)
        local_id = identifier if local_id == MISSING
        accessible_trip_scope.find_by!(client_id: local_id)
      end
      raise ActiveRecord::RecordNotFound unless trip.readable_by?(@user)

      trip
    end

    def accessible_trip_scope
      Trip.active.where(id: AccessScope.new(user: @user).active_trip_ids)
    end

    def trip_identifier_from(payload, operation)
      identifier = read_payload(payload, :trip_id, :tripID, :tripId)
      identifier == MISSING ? operation[:entity_id] : identifier
    end

    def find_child(scope, identifier)
      identifier = identifier.to_s.presence
      record = scope.find_by(id: identifier) if uuid?(identifier)
      record ||= scope.find_by(client_id: identifier) if identifier.present? && scope.klass.column_names.include?("client_id")
      record || scope.build
    end

    def find_record_by_local_or_server(model, identifier)
      record = model.find_by(id: identifier) if uuid?(identifier)
      record ||= model.find_by!(client_id: identifier) if model.column_names.include?("client_id")
      record
    end

    def find_generic_record(model, payload, operation, owner)
      if owner == :search_session
        session_identifier = read_payload(payload, :search_session_id, :searchSessionID, :owner_id, :ownerID)
        owner_record = SearchSession.where(user: @user).find_by(id: session_identifier) || SearchSession.where(user: @user).find_by(client_id: session_identifier)
        return model.find_or_initialize_by(owner: owner_record, client_id: local_id_from(payload, operation))
      end

      if model == PlaceListItem
        list = find_user_place_list(read_payload(payload, :place_list_id, :placeListID, :placeListId))
        return find_child(list.items, local_id_from(payload, operation))
      end

      scope = model.where(user: @user)
      find_child(scope, local_id_from(payload, operation))
    end

    def assign_generic_owner(record, payload, owner)
      case owner
      when :user
        record.user = @user if record.respond_to?(:user=)
        assign_trip_reference(record, payload)
      when :search_session
        if record.owner.blank?
          session_identifier = read_payload(payload, :search_session_id, :searchSessionID, :owner_id, :ownerID)
          record.owner = SearchSession.where(user: @user).find_by(id: session_identifier) || SearchSession.where(user: @user).find_by(client_id: session_identifier)
        end
      end
    end

    def assign_trip_reference(record, payload)
      return unless record.respond_to?(:trip=)

      trip_identifier = read_payload(payload, :trip_id, :tripID)
      return if trip_identifier == MISSING || trip_identifier.blank?

      record.trip = find_accessible_trip(trip_identifier, payload)
    end

    def find_user_place_list(identifier)
      PlaceList.where(user: @user).find_by(id: identifier) || PlaceList.where(user: @user).find_by(client_id: identifier)
    end

    def find_invite_for_operation(operation)
      payload = payload_hash(operation)
      identifier = read_payload(payload, :invite_id, :inviteID, :token)
      identifier = operation[:entity_id] if identifier == MISSING
      invite = TripInvite.find_by(token: identifier)
      invite ||= TripInvite.find(identifier) if uuid?(identifier)
      raise ActiveRecord::RecordNotFound if invite.blank?

      invite
    end

    def find_member_for_operation(operation)
      payload = payload_hash(operation)
      identifier = read_payload(payload, :member_id, :memberID)
      identifier = operation[:entity_id] if identifier == MISSING
      raise ActiveRecord::RecordNotFound unless uuid?(identifier)

      TripMember.find(identifier)
    end

    def segment_for_identifier(identifier, segment_map)
      return if identifier == MISSING || identifier.blank?
      return segment_map[identifier] if segment_map[identifier]

      TripSegment.find_by(id: identifier) || TripSegment.find_by(client_id: identifier)
    end

    def stop_for_identifier(identifier, stop_map)
      return if identifier == MISSING || identifier.blank?
      return stop_map[identifier] if stop_map[identifier]

      TripStop.find_by(id: identifier) || TripStop.find_by(client_id: identifier)
    end

    def save_with_event!(record, action, actor_device:, actor_user:, trip: nil)
      was_new = record.new_record?
      changed = record.changed?
      record.revision = record.revision.to_i + 1 if !was_new && changed && record.respond_to?(:revision=)
      record.save!
      EventRecorder.record!(record, action: action, actor_user: actor_user, actor_device: actor_device, trip: trip) if was_new || changed
      record
    end

    def soft_delete!(record, device:, reason:)
      return record if record.deleted_at.present?

      record.update!(deleted_at: Time.current, revision: record.revision.to_i + 1)
      DeletedRecordRecorder.record!(
        entity_type: RecordSerializer.type_for(record),
        entity_id: record.id,
        trip: RecordSerializer.trip_for(record),
        user: RecordSerializer.user_for(record),
        deleted_by_user: @user,
        deleted_by_device: device,
        reason: reason,
        revision: record.revision
      )
      record
    end

    def tombstone_missing_children(scope, seen_ids, device)
      return if seen_ids.empty? && scope.none?

      scope.where.not(client_id: [ nil, "" ]).where.not(client_id: seen_ids).find_each do |record|
        soft_delete!(record, device: device, reason: "deleted")
      end
    end

    def accepted_result(operation, server_id:, revision:, mappings: [])
      {
        operation_id: operation[:operation_id],
        status: "accepted",
        entity_type: operation[:entity_type],
        entity_id: operation[:entity_id],
        server_id: server_id,
        revision: revision,
        mappings: mappings.compact
      }
    end

    def rejected_result(operation, code, message, details = [])
      {
        operation_id: operation[:operation_id],
        status: "rejected",
        entity_type: operation[:entity_type],
        entity_id: operation[:entity_id],
        error: {
          code: code,
          message: message,
          details: Array(details)
        }
      }
    end

    def conflict_if_stale(operation, record)
      base_revision = operation[:base_revision]
      return if base_revision.blank? || base_revision.to_i >= record.revision.to_i

      {
        operation_id: operation[:operation_id],
        status: "conflict",
        entity_type: operation[:entity_type],
        entity_id: operation[:entity_id],
        server_id: record.id,
        revision: record.revision,
        conflict: {
          code: "stale_revision",
          message: "Operation base revision is older than the current server revision.",
          base_revision: base_revision.to_i,
          current_revision: record.revision,
          resolution: "pull_latest"
        }
      }
    end

    def mapping(entity_type, entity_id, record)
      return if entity_id.blank?

      {
        entity_type: entity_type,
        entity_id: entity_id,
        server_id: record.id,
        revision: record.respond_to?(:revision) ? record.revision : 1
      }
    end

    def action_for(was_new)
      was_new ? "created" : "updated"
    end

    def local_id_from(payload, operation)
      value = read_payload(payload, :id, :client_id, :clientID, :clientId)
      value = operation[:entity_id] if value == MISSING && operation.present?
      value
    end

    def payload_hash(operation)
      payload = operation[:payload]
      return payload.with_indifferent_access if payload.is_a?(Hash)

      { encoded_payload: preserve_payload(payload) }.with_indifferent_access
    end

    def preserve_payload(payload)
      case payload
      when ActionController::Parameters
        payload.to_unsafe_h
      when Hash, Array, String, Numeric, TrueClass, FalseClass, NilClass
        payload
      else
        payload.as_json
      end
    end

    def array_payload(payload, *keys)
      value = read_payload(payload, *keys)
      return [] if value == MISSING || value.blank?

      Array(value)
    end

    def assign_value(record, attribute, payload, *keys, default: MISSING)
      value = read_payload(payload, *keys)
      value = default if value == MISSING && default != MISSING
      return if value == MISSING

      record.public_send("#{attribute}=", value)
    end

    def read_payload(payload, *keys)
      keys.each do |key|
        return payload[key] if payload.key?(key)
      end
      MISSING
    end

    def payload_has_any?(payload, *keys)
      keys.any? { |key| payload.key?(key) }
    end

    def parse_time(value)
      return if value.blank?

      Time.zone.parse(value.to_s)
    rescue ArgumentError
      nil
    end

    def seconds_from_now(value)
      return if value == MISSING || value.blank?

      value.to_i.seconds.from_now
    end

    def uuid?(value)
      value.to_s.match?(UUID_PATTERN)
    end
  end
end
