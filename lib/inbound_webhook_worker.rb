class InboundWebhookWorker
  include Sidekiq::Worker
  def perform(url, body)
    begin
      RestClient.post(url, body, content_type: 'text/plain')
    rescue RestClient::BadRequest
    end
  end
end
