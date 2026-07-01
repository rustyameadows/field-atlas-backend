module Api
  module V1
    module Serializers
      module_function

      def auth(user:, api_session:, access_token:, refresh_token:)
        {
          user: user(user),
          session: session(api_session, access_token, refresh_token)
        }
      end

      def user(user)
        {
          id: user.id,
          display_name: user.display_name,
          email: user.email,
          email_verified: user.email_verified,
          time_zone: user.time_zone,
          status: user.status,
          revision: user.revision,
          created_at: iso(user.created_at),
          updated_at: iso(user.updated_at)
        }
      end

      def session(api_session, access_token, refresh_token)
        {
          id: api_session.id,
          user_id: api_session.user_id,
          device_id: api_session.device_id,
          access_token: access_token,
          refresh_token: refresh_token,
          expires_at: iso(api_session.expires_at),
          refresh_expires_at: iso(api_session.refresh_expires_at)
        }
      end

      def device(device)
        {
          id: device.id,
          user_id: device.user_id,
          client_device_id: device.client_device_id,
          name: device.name,
          platform: device.platform,
          app_version: device.app_version,
          build_number: device.build_number,
          push_environment: device.push_environment,
          last_seen_at: iso(device.last_seen_at),
          revision: device.revision,
          created_at: iso(device.created_at),
          updated_at: iso(device.updated_at)
        }
      end

      def invite(invite)
        {
          id: invite.id,
          trip_id: invite.trip_id,
          trip_title: invite.trip.title,
          invited_by_user_id: invite.invited_by_user_id,
          inviter_display_name: invite.invited_by_user.display_name,
          accepted_by_user_id: invite.accepted_by_user_id,
          token: invite.token,
          url: invite.url,
          role: invite.role,
          status: invite.status,
          expires_at: iso(invite.expires_at),
          accepted_at: iso(invite.accepted_at),
          deleted_at: iso(invite.deleted_at),
          revision: invite.revision,
          created_at: iso(invite.created_at),
          updated_at: iso(invite.updated_at)
        }
      end

      def invite_preview(invite)
        {
          token: invite.token,
          trip_title: invite.trip.title,
          inviter_display_name: invite.invited_by_user.display_name,
          role: invite.role,
          status: invite.status,
          expires_at: iso(invite.expires_at)
        }
      end

      def member(member)
        {
          id: member.id,
          trip_id: member.trip_id,
          user_id: member.user_id,
          display_name: member.display_name,
          role: member.role,
          status: member.status,
          joined_at: iso(member.joined_at),
          deleted_at: iso(member.deleted_at),
          revision: member.revision,
          created_at: iso(member.created_at),
          updated_at: iso(member.updated_at)
        }
      end

      def deleted_record(record)
        {
          id: record.id,
          entity_type: record.entity_type,
          entity_id: record.entity_id,
          trip_id: record.trip_id,
          user_id: record.user_id,
          deleted_at: iso(record.deleted_at),
          revision: record.revision,
          reason: record.reason,
          metadata: record.metadata || {}
        }
      end

      def iso(value)
        value&.utc&.iso8601
      end
    end
  end
end
