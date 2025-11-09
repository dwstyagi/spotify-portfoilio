Rails.application.routes.draw do
  # Admin OAuth routes
  namespace :admin do
    get "auth", to: "auth#index"
    get "callback", to: "auth#callback"
  end

  # Spotify API routes
  scope :spotify do
    get "/", to: "spotify#index", as: :spotify
    get "top-tracks", to: "spotify#top_tracks"
    get "now-playing", to: "spotify#now_playing"
    get "artists", to: "spotify#artists"
    post "pause", to: "spotify#pause"
    post "play/:track_id", to: "spotify#play", as: :play_track
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "spotify#index"
end
