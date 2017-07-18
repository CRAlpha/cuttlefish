class WebhookWorker
  include Sidekiq::Worker
  def perform(url, body)
    RestClient.post(url, body, content_type: 'text')
  end
end
