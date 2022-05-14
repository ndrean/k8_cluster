import Config

config :k8_cluster,
  cookie: "release_secret",
  env: config_env()

import_config "#{Mix.env()}.exs"
