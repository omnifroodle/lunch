import Config
config :astra,
  host: System.get_env("CASS_HOST"),
  username: System.get_env("CASS_USERNAME"),
  password: System.get_env("CASS_PASSWORD")
