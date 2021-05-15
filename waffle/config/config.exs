import Config

# Configures the endpoint
config :livebook, LivebookWeb.Endpoint,
  url: [host: "localhost"],
  pubsub_server: Livebook.PubSub,
  live_view: [signing_salt: "livebook"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Sets the default authentication mode to token
config :livebook, :authentication_mode, :token

# Sets the default runtime to ElixirStandalone.
# This is the desired default most of the time,
# but in some specific use cases you may want
# to configure that to the Embedded runtime instead.
# Also make sure the configured runtime has
# a synchronous `init/0` method.
config :livebook, :default_runtime, Livebook.Runtime.ElixirStandalone

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
