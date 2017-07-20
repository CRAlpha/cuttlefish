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


schedule_file = "config/schedule.yml"

if File.exists?(schedule_file) && Sidekiq.server?
  Sidekiq::Cron::Job.load_from_hash! YAML.load_file(schedule_file)
end
