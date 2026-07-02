module Api
  module V1
    class TripInvitesController < BaseController
      before_action :authenticate_api_session!, only: %i[create accept]

      def create
        trip = Trip.find(params[:trip_id])
        return render_error("forbidden", "You do not have permission to invite members.", status: :forbidden) unless trip.manageable_by?(current_user)

        invite = TripInvite.create!(
          trip: trip,
          invited_by_user: current_user,
          role: params[:role].presence || "editor",
          expires_at: expires_at,
          url: invite_url_for(nil)
        )
        invite.update!(url: invite_url_for(invite.token))
        ::Sync::EventRecorder.record!(invite, action: "created", actor_user: current_user, actor_device: current_device, trip: trip)

        render json: { invite: Serializers.invite(invite) }, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render_error("invalid_invite", e.record.errors.full_messages.to_sentence, status: :unprocessable_entity)
      end

      def show
        invite = TripInvite.find_by!(token: params[:token])
        render json: { invite: Serializers.invite_preview(invite) }
      end

      def accept
        invite = TripInvite.find_by!(token: params[:token])
        return render_error("invalid_invite", "Invite is not pending.", status: :unprocessable_entity) unless invite.pending?

        member = TripMember.find_or_initialize_by(trip: invite.trip, user: current_user)
        member.role = invite.role
        member.status = "active"
        member.deleted_at = nil
        member.display_name = current_user.display_name
        member.joined_at ||= Time.current

        TripInvite.transaction do
          was_new_member = member.new_record?
          member.revision += 1 if member.persisted? && member.changed?
          member.save!
          invite.accept!(current_user)
          ::Sync::EventRecorder.record!(member, action: was_new_member ? "created" : "updated", actor_user: current_user, actor_device: current_device, trip: invite.trip)
          ::Sync::EventRecorder.record!(invite, action: "updated", actor_user: current_user, actor_device: current_device, trip: invite.trip)
        end

        render json: { member: Serializers.member(member), invite: Serializers.invite(invite) }
      rescue ActiveRecord::RecordInvalid => e
        render_error("invalid_invite_acceptance", e.record.errors.full_messages.to_sentence, status: :unprocessable_entity)
      end

      private

      def expires_at
        seconds = params[:expires_in_seconds].presence
        seconds ? seconds.to_i.seconds.from_now : nil
      end

      def invite_url_for(token)
        host = ENV.fetch("FIELD_ATLAS_INVITE_HOST", "http://127.0.0.1:3000")
        token.present? ? "#{host}/invites/#{token}" : host
      end
    end
  end
end
