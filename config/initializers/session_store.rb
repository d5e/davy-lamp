# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_monitor_session',
  :secret      => '9370554ed20803805ce3efeb21b321697962635b698bb0de9e6fbcd67ff71c06b3a5895123de331c54ba2ca5d2285e3c02513089d0c41ae75e1dfdfabd4a91b7'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
