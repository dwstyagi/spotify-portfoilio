class SpotifyToken < ApplicationRecord
  validates :access_token, :refresh_token, :expires_at, presence: true

  def expired?
    expires_at <= Time.current
  end

  def valid_token?
    !expired?
  end

  def refresh_if_needed!
    return access_token if valid_token?

    refresh_access_token!
    access_token
  end

  def self.current
    first_or_create do |token|
      token.access_token = ""
      token.refresh_token = ""
      token.expires_at = Time.current
      token.token_type = "Bearer"
      token.scope = ""
    end
  end

  private

  def refresh_access_token!
    response = RestClient.post(
      "https://accounts.spotify.com/api/token",
      {
        grant_type: "refresh_token",
        refresh_token: refresh_token,
        client_id: ENV["SPOTIFY_CLIENT_ID"],
        client_secret: ENV["SPOTIFY_CLIENT_SECRET"]
      }
    )

    data = JSON.parse(response.body)

    update!(
      access_token: data["access_token"],
      expires_at: Time.current + data["expires_in"].seconds
    )
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error("Failed to refresh Spotify token: #{e.response}")
    raise
  end
end
