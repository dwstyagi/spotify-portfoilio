class CreateSpotifyTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :spotify_tokens do |t|
      t.text :access_token
      t.text :refresh_token
      t.datetime :expires_at
      t.string :token_type
      t.string :scope

      t.timestamps
    end
  end
end
