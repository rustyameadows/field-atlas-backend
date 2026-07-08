class TripInviteUrl
  DEFAULT_WEB_BASE_URL = "https://field-atlas.com"

  def self.for(token)
    new(token).to_s
  end

  def initialize(token)
    @token = token.to_s
  end

  def to_s
    raise ArgumentError, "token must be present" if @token.blank?

    "#{web_base_url}/invites/?token=#{ERB::Util.url_encode(@token)}"
  end

  private

  def web_base_url
    value = ENV["FIELD_ATLAS_WEB_BASE_URL"].presence
    raise KeyError, "FIELD_ATLAS_WEB_BASE_URL is required" if value.blank? && Rails.env.production?

    (value || DEFAULT_WEB_BASE_URL).delete_suffix("/")
  end
end
