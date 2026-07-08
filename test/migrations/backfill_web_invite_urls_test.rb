require "test_helper"
require Rails.root.join("db/migrate/20260707010000_backfill_web_invite_urls")

class BackfillWebInviteUrlsTest < ActiveSupport::TestCase
  test "rewrites existing invite urls from stored tokens" do
    user = User.create!(display_name: "Avery Field", email: "avery-migration@example.com")
    trip = Trip.create!(owner_user: user, title: "Migration Trip")
    invite = TripInvite.create!(
      trip: trip,
      invited_by_user: user,
      token: "abc+123/?",
      url: "http://127.0.0.1:3000" + "/invites/abc+123/?"
    )

    BackfillWebInviteUrls.new.up

    assert_equal "https://field-atlas.com/invites/?token=abc%2B123%2F%3F", invite.reload.url
  end
end
