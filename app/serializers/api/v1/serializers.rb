module Api
  module V1
    module Serializers
      module_function

      def auth(user:, api_session:, access_token:, refresh_token:, device: nil)
        response = {
          user: user(user),
          session: session(api_session, access_token, refresh_token)
        }
        response[:device] = self.device(device) if device.present?
        response
      end

      def user(user)
        {
          id: user.id,
          apple_user_identifier: apple_user_identifier(user),
          display_name: user.display_name,
          email: user.email,
          email_verified: user.email_verified,
          is_admin: user.admin?,
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

      def asset(asset)
        {
          id: asset.id,
          server_id: asset.id,
          client_id: asset.client_id,
          uploaded_by_user_id: asset.uploaded_by_user_id,
          asset_kind: asset.asset_kind,
          mime_type: asset.mime_type,
          original_filename: asset.original_filename,
          byte_size: asset.byte_size,
          checksum: asset.checksum,
          storage_provider: asset.storage_provider,
          storage_key: asset.storage_key,
          width: asset.width,
          height: asset.height,
          duration_ms: asset.duration_ms,
          status: asset.status,
          metadata: asset.metadata || {},
          deleted_at: iso(asset.deleted_at),
          revision: asset.revision,
          created_at: iso(asset.created_at),
          updated_at: iso(asset.updated_at)
        }
      end

      def asset_link(link)
        {
          id: link.id,
          server_id: link.id,
          asset_id: link.asset_id,
          created_by_user_id: link.created_by_user_id,
          attachable_type: link.attachable_type,
          attachable_id: link.attachable_id,
          attachable_ref: link.attachable_ref || {},
          role: link.role,
          caption: link.caption,
          sort_order: link.sort_order,
          metadata: link.metadata || {},
          deleted_at: iso(link.deleted_at),
          revision: link.revision,
          created_at: iso(link.created_at),
          updated_at: iso(link.updated_at)
        }
      end

      def transfer_intent(intent)
        {
          method: intent.fetch(:method),
          url: intent.fetch(:url),
          headers: intent.fetch(:headers),
          expires_at: iso(intent.fetch(:expires_at))
        }
      end

      def download_intent(asset, intent)
        transfer_intent(intent).merge(asset_id: asset.id)
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

      def apple_user_identifier(user)
        identity = if user.association(:auth_identities).loaded?
          user.auth_identities.find { |auth_identity| auth_identity.provider == "apple" }
        else
          user.auth_identities.find_by(provider: "apple")
        end
        identity&.provider_subject
      end
    end
  end
end
