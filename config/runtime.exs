import Config

if config_env() == :prod do
  app_domain =
    System.get_env("APP_DOMAIN") ||
      raise """
      environment variable APP_DOMAIN is missing.
      For example: sampleapp.com
      """

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :fen_gen, FenGenWeb.Endpoint,
    server: true,
    url: [host: app_domain, port: 80],
    http: [
      port: String.to_integer(System.get_env("APP_PORT") || "4000"),
      transport_options: [socket_opts: [:inet6]]
    ],
    secret_key_base: secret_key_base,
    cache_static_manifest: "priv/static/cache_manifest.json"
end
