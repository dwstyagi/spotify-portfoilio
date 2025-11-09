class SpotifyController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :check_authentication
  before_action :initialize_service

  # GET /spotify - Main endpoint showing all data
  def index
    top_tracks_data = @service.top_tracks(10)
    now_playing_data = @service.now_playing
    artists_data = @service.followed_artists(20)

    render json: {
      now_playing: now_playing_data,
      top_tracks: top_tracks_data,
      followed_artists: artists_data,
      endpoints: {
        top_tracks: "#{request.base_url}/spotify/top-tracks",
        now_playing: "#{request.base_url}/spotify/now-playing",
        artists: "#{request.base_url}/spotify/artists",
        pause: "POST #{request.base_url}/spotify/pause",
        play: "POST #{request.base_url}/spotify/play/:track_id"
      }
    }, status: :ok
  rescue StandardError => e
    render_error(e)
  end

  # GET /spotify/top-tracks
  def top_tracks
    data = @service.top_tracks(10)
    render json: data, status: :ok
  rescue StandardError => e
    render_error(e)
  end

  # GET /spotify/now-playing
  def now_playing
    data = @service.now_playing
    render json: data, status: :ok
  rescue StandardError => e
    render_error(e)
  end

  # GET /spotify/artists
  def artists
    data = @service.followed_artists(20)
    render json: data, status: :ok
  rescue StandardError => e
    render_error(e)
  end

  # POST /spotify/pause
  def pause
    result = @service.pause_playback

    if result[:success]
      render json: result, status: :ok
    else
      render json: result, status: :unprocessable_entity
    end
  rescue StandardError => e
    render_error(e)
  end

  # POST /spotify/play/:track_id
  def play
    track_id = params[:track_id]

    if track_id.blank?
      render json: { error: "Track ID is required" }, status: :bad_request
      return
    end

    result = @service.play_track(track_id)

    if result[:success]
      render json: result, status: :ok
    else
      render json: result, status: :unprocessable_entity
    end
  rescue StandardError => e
    render_error(e)
  end

  private

  def check_authentication
    token = SpotifyToken.first

    if token.nil? || token.access_token.blank?
      render json: {
        error: "Not authenticated",
        message: "Please authenticate with Spotify first",
        auth_url: "#{request.base_url}/admin/auth"
      }, status: :unauthorized
    end
  end

  def initialize_service
    @service = SpotifyService.new
  end

  def render_error(error)
    Rails.logger.error("Spotify API Error: #{error.message}")
    Rails.logger.error(error.backtrace.join("\n"))

    case error
    when RestClient::Unauthorized
      render json: {
        error: "Authentication expired",
        message: "Your Spotify authentication has expired. Please re-authenticate.",
        auth_url: "#{request.base_url}/admin/auth"
      }, status: :unauthorized
    when RestClient::Forbidden
      render json: {
        error: "Permission denied",
        message: "You may need Spotify Premium for this feature or lack required permissions"
      }, status: :forbidden
    when RestClient::NotFound
      render json: {
        error: "Resource not found",
        message: "The requested Spotify resource was not found"
      }, status: :not_found
    else
      render json: {
        error: "Internal server error",
        message: error.message
      }, status: :internal_server_error
    end
  end
end
