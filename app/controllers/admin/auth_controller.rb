module Admin
  class AuthController < ApplicationController
    def index
      # Redirect to Spotify authorization
      scope = %w[
        user-read-currently-playing
        user-top-read
        user-follow-read
        user-modify-playback-state
        user-read-playback-state
      ].join(" ")

      auth_url = "https://accounts.spotify.com/authorize?" + {
        client_id: ENV["SPOTIFY_CLIENT_ID"],
        response_type: "code",
        redirect_uri: ENV["SPOTIFY_REDIRECT_URI"],
        scope: scope,
        show_dialog: true
      }.to_query

      redirect_to auth_url, allow_other_host: true
    end

    def callback
      # Handle OAuth callback
      code = params[:code]

      if code.blank?
        render json: { error: "Authorization failed", message: params[:error] }, status: :unauthorized
        return
      end

      # Exchange code for access token
      response = RestClient.post(
        "https://accounts.spotify.com/api/token",
        {
          grant_type: "authorization_code",
          code: code,
          redirect_uri: ENV["SPOTIFY_REDIRECT_URI"],
          client_id: ENV["SPOTIFY_CLIENT_ID"],
          client_secret: ENV["SPOTIFY_CLIENT_SECRET"]
        }
      )

      data = JSON.parse(response.body)

      # Store tokens in database
      token = SpotifyToken.current
      token.update!(
        access_token: data["access_token"],
        refresh_token: data["refresh_token"],
        expires_at: Time.current + data["expires_in"].seconds,
        token_type: data["token_type"],
        scope: data["scope"]
      )

      render json: {
        success: true,
        message: "Successfully authenticated with Spotify!",
        expires_at: token.expires_at
      }
    rescue RestClient::ExceptionWithResponse => e
      render json: { error: "Failed to get access token", details: e.response }, status: :bad_request
    end
  end
end
