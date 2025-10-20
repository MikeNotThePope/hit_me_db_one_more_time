import Config

# Runtime configuration (only loads in non-test environments)
if config_env() != :test do
  # This is loaded during runtime
end
