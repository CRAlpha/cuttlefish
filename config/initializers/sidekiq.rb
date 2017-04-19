Sidekiq.remove_delay!

Sidekiq.default_worker_options = {
  retry: 4
}

redis_options = {
  namespace: 'cuttlefish_job',
  driver: 'hiredis',
  timeout: 2,
  url: "redis://localhost:6379/6"
}

Sidekiq.configure_server do |config|
  config.redis = redis_options
end

Sidekiq.configure_client do |config|
  config.redis = redis_options
end
