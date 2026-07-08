class BackfillWebInviteUrls < ActiveRecord::Migration[8.1]
  WEB_BASE_URL = "https://field-atlas.com"

  class TripInvite < ActiveRecord::Base
    self.table_name = "trip_invites"
  end

  def up
    TripInvite.where.not(token: [ nil, "" ]).find_each do |invite|
      invite.update_columns(url: web_invite_url(invite.token))
    end
  end

  def down
    # The previous API-domain invite URL cannot be restored reliably.
  end

  private

  def web_invite_url(token)
    "#{WEB_BASE_URL}/invites/?token=#{ERB::Util.url_encode(token)}"
  end
end
