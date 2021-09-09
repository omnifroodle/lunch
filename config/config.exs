# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :lunch,
  ecto_repos: [Lunch.Repo]

# Configures the endpoint
config :lunch, LunchWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "MTK0Fv+TwMDTyH6DpmmDJPQG3TPrUmK0XHkQrSvfV9cobf8898ZM7N6Uy2JUhgvD",
  render_errors: [view: LunchWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Lunch.PubSub,
  live_view: [signing_salt: "j78B2Qo0"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
