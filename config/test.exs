use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :fen_gen, FenGenWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :fen_gen,
  upload_path: "priv/uploads",
  scripts_path: "priv/scripts"
