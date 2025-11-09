# Spotify API Portfolio Integration

A Ruby on Rails API that integrates with Spotify to display your top tracks, currently playing song, followed artists, and control playback. Built for deployment on Railway with PostgreSQL.

## Features

- View your top 10 tracks
- See currently playing song
- List followed artists
- Pause current playback
- Play any of your top tracks
- OAuth 2.0 authentication with Spotify
- Automatic token refresh
- RESTful JSON API
- Pretty-printed JSON responses

## Tech Stack

- **Framework**: Ruby on Rails 8.0
- **Database**: PostgreSQL
- **Gems**:
  - `rspotify` - Spotify API wrapper
  - `rest-client` - HTTP client
  - `dotenv-rails` - Environment variables
- **Deployment**: Railway
- **Authentication**: Spotify OAuth 2.0

## Prerequisites

- Ruby 3.3+
- PostgreSQL
- Spotify Developer Account
- Spotify Premium (required for playback control features)

## Local Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd spotify-portfolio
```

### 2. Install Dependencies

```bash
bundle install
```

### 3. Configure Spotify Developer App

Follow the guide in `SPOTIFY_SETUP_GUIDE.md` to:
1. Create a Spotify Developer app
2. Get your Client ID and Client Secret
3. Set redirect URI to `http://localhost:3000/admin/callback`

### 4. Set Environment Variables

Create a `.env` file:

```bash
cp .env.example .env
```

Update `.env` with your credentials:

```env
SPOTIFY_CLIENT_ID=your_client_id_here
SPOTIFY_CLIENT_SECRET=your_client_secret_here
SPOTIFY_REDIRECT_URI=http://localhost:3000/admin/callback

DB_USERNAME=postgres
DB_PASSWORD=your_password
DB_HOST=localhost
DB_PORT=5432
```

### 5. Set Up Database

```bash
rails db:create
rails db:migrate
```

### 6. Start the Server

```bash
rails server
```

The app will be available at `http://localhost:3000`

### 7. Authenticate with Spotify

1. Visit: `http://localhost:3000/admin/auth`
2. Log in with your Spotify account
3. Authorize the application
4. You'll receive a JSON response confirming successful authentication

## API Documentation

All endpoints return pretty-printed JSON.

### Base URL

**Local**: `http://localhost:3000/spotify`
**Production**: `https://your-app.up.railway.app/spotify`

---

### GET `/spotify`

Main endpoint that returns all data in one response.

**Response**:
```json
{
  "now_playing": {
    "playing": true,
    "track": {
      "name": "Song Name",
      "artist": "Artist Name",
      "album": "Album Name",
      "album_art": "https://...",
      "duration_ms": 234000,
      "progress_ms": 45000,
      "uri": "spotify:track:...",
      "external_url": "https://open.spotify.com/track/..."
    }
  },
  "top_tracks": {
    "total": 50,
    "tracks": [...]
  },
  "followed_artists": {
    "total": 42,
    "artists": [...]
  },
  "endpoints": {
    "top_tracks": "http://localhost:3000/spotify/top-tracks",
    "now_playing": "http://localhost:3000/spotify/now-playing",
    "artists": "http://localhost:3000/spotify/artists",
    "pause": "http://localhost:3000/spotify/pause",
    "play": "POST http://localhost:3000/spotify/play/:track_id"
  }
}
```

---

### GET `/spotify/top-tracks`

Returns your top 10 most listened to tracks.

**Response**:
```json
{
  "total": 50,
  "tracks": [
    {
      "name": "Track Name",
      "artist": "Artist Name",
      "album": "Album Name",
      "album_art": "https://i.scdn.co/image/...",
      "duration_ms": 234000,
      "popularity": 85,
      "uri": "spotify:track:abc123",
      "track_id": "abc123",
      "external_url": "https://open.spotify.com/track/abc123",
      "preview_url": "https://p.scdn.co/mp3-preview/..."
    }
  ]
}
```

---

### GET `/spotify/now-playing`

Returns the currently playing track.

**Response (when playing)**:
```json
{
  "playing": true,
  "track": {
    "name": "Current Song",
    "artist": "Artist Name",
    "album": "Album Name",
    "album_art": "https://...",
    "duration_ms": 234000,
    "progress_ms": 45000,
    "uri": "spotify:track:...",
    "external_url": "https://open.spotify.com/track/..."
  }
}
```

**Response (when nothing playing)**:
```json
{
  "playing": false,
  "message": "No track currently playing"
}
```

---

### GET `/spotify/artists`

Returns list of artists you follow.

**Response**:
```json
{
  "total": 42,
  "artists": [
    {
      "name": "Artist Name",
      "genres": ["pop", "rock"],
      "popularity": 87,
      "followers": 1234567,
      "image": "https://i.scdn.co/image/...",
      "external_url": "https://open.spotify.com/artist/...",
      "uri": "spotify:artist:..."
    }
  ]
}
```

---

### POST `/spotify/pause`

Pauses current playback.

**Response (success)**:
```json
{
  "success": true,
  "message": "Playback paused"
}
```

**Response (Premium required)**:
```json
{
  "success": false,
  "error": "Premium required",
  "message": "You need Spotify Premium to control playback"
}
```

**Response (no active device)**:
```json
{
  "success": false,
  "error": "No active device",
  "message": "No active playback device found"
}
```

---

### POST `/spotify/play/:track_id`

Starts playing a specific track.

**Parameters**:
- `track_id` (required): Spotify track ID or URI

**Example**:
```bash
curl -X POST http://localhost:3000/spotify/play/4cOdK2wGLETKBW3PvgPWqT
```

**Response (success)**:
```json
{
  "success": true,
  "message": "Track started playing",
  "track_uri": "spotify:track:4cOdK2wGLETKBW3PvgPWqT"
}
```

**Note**: You can get track IDs from the `/spotify/top-tracks` endpoint response.

---

## Error Responses

### 401 Unauthorized
```json
{
  "error": "Not authenticated",
  "message": "Please authenticate with Spotify first",
  "auth_url": "http://localhost:3000/admin/auth"
}
```

### 403 Forbidden
```json
{
  "error": "Permission denied",
  "message": "You may need Spotify Premium for this feature or lack required permissions"
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal server error",
  "message": "Error details..."
}
```

## Deployment

See `RAILWAY_DEPLOYMENT.md` for complete deployment instructions for Railway.

### Quick Deployment Steps:

1. Push code to GitHub
2. Create new Railway project from GitHub repo
3. Add PostgreSQL database
4. Set environment variables
5. Update Spotify app redirect URI
6. Deploy and authenticate

## Project Structure

```
spotify-portfolio/
├── app/
│   ├── controllers/
│   │   ├── admin/
│   │   │   └── auth_controller.rb    # OAuth authentication
│   │   └── spotify_controller.rb     # Main API endpoints
│   ├── models/
│   │   └── spotify_token.rb          # Token storage & refresh
│   └── services/
│       └── spotify_service.rb        # Spotify API wrapper
├── config/
│   ├── database.yml                  # Database configuration
│   └── routes.rb                     # API routes
├── db/
│   └── migrate/                      # Database migrations
├── .env                              # Environment variables (local)
├── .env.example                      # Example env file
├── Procfile                          # Railway process file
├── SPOTIFY_SETUP_GUIDE.md           # Spotify app setup guide
└── RAILWAY_DEPLOYMENT.md            # Deployment guide
```

## Required Spotify Scopes

- `user-read-currently-playing` - Read currently playing track
- `user-top-read` - Read top tracks
- `user-follow-read` - Read followed artists
- `user-modify-playback-state` - Control playback (pause/play)
- `user-read-playback-state` - Read playback state

## Notes

- **Spotify Premium** is required for playback control features (pause/play)
- Free accounts can still access: top tracks, now playing (read-only), and followed artists
- Tokens automatically refresh when expired
- Only one authentication is stored (single-user app)
- All JSON responses are pretty-printed for easy browser viewing

## Troubleshooting

### "No active device" error

Open Spotify on any device (phone, desktop, web player) before using playback controls.

### "Premium required" error

Upgrade to Spotify Premium or use read-only endpoints (top tracks, artists, now playing).

### Authentication expired

Visit `/admin/auth` to re-authenticate.

### Database connection errors

Check your PostgreSQL configuration in `.env` and ensure PostgreSQL is running.

## License

MIT

## Author

Your Name - Portfolio Project
