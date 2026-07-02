module Api
  module V1
    class TripMembersController < BaseController
      before_action :authenticate_api_session!
      before_action :set_trip
      before_action :require_owner!

      def update
        member = @trip.members.find(params[:id])
        return render_error("invalid_member_role", "Cannot remove the last active owner.", status: :unprocessable_entity) if would_remove_last_owner?(member, params[:role])

        member.role = params[:role] if params[:role].present?
        member.revision += 1 if member.changed?
        member.save!
        ::Sync::EventRecorder.record!(member, action: "updated", actor_user: current_user, actor_device: current_device, trip: @trip)
        render json: { member: Serializers.member(member) }
      rescue ActiveRecord::RecordInvalid => e
        render_error("invalid_member", e.record.errors.full_messages.to_sentence, status: :unprocessable_entity)
      end

      def destroy
        member = @trip.members.find(params[:id])
        return render_error("invalid_member_removal", "Cannot remove the last active owner.", status: :unprocessable_entity) if member.owner? && active_owner_count <= 1

        TripMember.transaction do
          member.remove!
          ::Sync::EventRecorder.record!(member, action: "updated", actor_user: current_user, actor_device: current_device, trip: @trip)
          ::Sync::DeletedRecordRecorder.record!(
            entity_type: "trip",
            entity_id: @trip.id,
            trip: @trip,
            user: member.user,
            deleted_by_user: current_user,
            deleted_by_device: current_device,
            reason: "access_revoked",
            revision: @trip.revision
          )
        end

        render json: { member: Serializers.member(member) }
      end

      private

      def set_trip
        @trip = Trip.find(params[:trip_id])
      end

      def require_owner!
        return if @trip.manageable_by?(current_user)

        render_error("forbidden", "Only trip owners can manage members.", status: :forbidden)
      end

      def would_remove_last_owner?(member, next_role)
        member.owner? && next_role.present? && next_role != "owner" && active_owner_count <= 1
      end

      def active_owner_count
        @active_owner_count ||= @trip.members.active.where(role: "owner").count
      end
    end
  end
end
