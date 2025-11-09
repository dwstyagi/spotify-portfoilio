class SpotifyService
  SPOTIFY_API_BASE = "https://api.spotify.com/v1"

  def initialize
    @token = SpotifyToken.current
  end

  # Get user's top 10 tracks
  def top_tracks(limit = 10)
    response = make_request(
      :get,
      "#{SPOTIFY_API_BASE}/me/top/tracks",
      { limit: limit, time_range: "medium_term" }
    )

    parse_tracks(response)
  end

  # Get currently playing track
  def now_playing
    response = make_request(:get, "#{SPOTIFY_API_BASE}/me/player/currently-playing")

    if response.code == 204 || response.body.blank?
      return { playing: false, message: "No track currently playing" }
    end

    data = JSON.parse(response.body)

    if data["item"].nil?
      return { playing: false, message: "No track currently playing" }
    end

    {
      playing: true,
      track: {
        name: data["item"]["name"],
        artist: data["item"]["artists"].map { |a| a["name"] }.join(", "),
        album: data["item"]["album"]["name"],
        album_art: data["item"]["album"]["images"].first&.dig("url"),
        duration_ms: data["item"]["duration_ms"],
        progress_ms: data["progress_ms"],
        uri: data["item"]["uri"],
        external_url: data["item"]["external_urls"]["spotify"]
      }
    }
  end

  # Get followed artists
  def followed_artists(limit = 20)
    response = make_request(
      :get,
      "#{SPOTIFY_API_BASE}/me/following",
      { type: "artist", limit: limit }
    )

    data = JSON.parse(response.body)

    {
      total: data.dig("artists", "total"),
      artists: data.dig("artists", "items")&.map do |artist|
        {
          name: artist["name"],
          genres: artist["genres"],
          popularity: artist["popularity"],
          followers: artist["followers"]["total"],
          image: artist["images"].first&.dig("url"),
          external_url: artist["external_urls"]["spotify"],
          uri: artist["uri"]
        }
      end || []
    }
  end

  # Pause current playback
  def pause_playback
    response = make_request(:put, "#{SPOTIFY_API_BASE}/me/player/pause")

    if response.code == 204
      { success: true, message: "Playback paused" }
    elsif response.code == 403
      { success: false, error: "Premium required", message: "You need Spotify Premium to control playback" }
    else
      { success: false, error: "Failed to pause", message: "Could not pause playback" }
    end
  rescue RestClient::NotFound
    { success: false, error: "No active device", message: "No active playback device found" }
  end

  # Play a specific track
  def play_track(track_uri)
    # Format URI if needed
    track_uri = "spotify:track:#{track_uri}" unless track_uri.start_with?("spotify:")

    response = make_request(
      :put,
      "#{SPOTIFY_API_BASE}/me/player/play",
      {},
      { uris: [track_uri] }.to_json
    )

    if response.code == 204
      { success: true, message: "Track started playing", track_uri: track_uri }
    elsif response.code == 403
      { success: false, error: "Premium required", message: "You need Spotify Premium to control playback" }
    else
      { success: false, error: "Failed to play", message: "Could not start playback" }
    end
  rescue RestClient::NotFound
    { success: false, error: "No active device", message: "No active playback device found. Please open Spotify on a device first." }
  end

  private

  def make_request(method, url, params = {}, body = nil)
    # Ensure we have a valid token
    access_token = @token.refresh_if_needed!

    headers = {
      Authorization: "Bearer #{access_token}",
      "Content-Type": "application/json"
    }

    case method
    when :get
      RestClient.get(url, { params: params, **headers })
    when :post
      RestClient.post(url, body, headers)
    when :put
      if body
        RestClient.put(url, body, headers)
      else
        RestClient.put(url, {}, headers)
      end
    end
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error("Spotify API Error: #{e.response}")
    raise
  end

  def parse_tracks(response)
    data = JSON.parse(response.body)

    {
      total: data["total"],
      tracks: data["items"].map do |item|
        {
          name: item["name"],
          artist: item["artists"].map { |a| a["name"] }.join(", "),
          album: item["album"]["name"],
          album_art: item["album"]["images"].first&.dig("url"),
          duration_ms: item["duration_ms"],
          popularity: item["popularity"],
          uri: item["uri"],
          track_id: item["id"],
          external_url: item["external_urls"]["spotify"],
          preview_url: item["preview_url"]
        }
      end
    }
  end
end
