import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :text_to_shader_backend, TextToShaderBackendWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "5IRx+xb5tPoo4yVlU7pCQar9RfF62vwL1S2zdKUw6x+N7z/ekEinTW7g/JqlqTe2",
  server: false

# In test we don't send emails
config :text_to_shader_backend, TextToShaderBackend.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
