class EventWebhookWorker
  include Sidekiq::Worker
  def perform
    App.where.not(event_webhook: nil).find_each do |app|
      next unless app.event_webhook =~ URI::regexp
      query = app.deliveries.includes(:address).where(reported: false).where.not(status: ['sent', 'not_sent'])
      events = []
      query.find_each do |delivery|
        events << { event: delivery.status,
                    message_id: delivery.email_id,
                    email: delivery.address.text }
      end

      begin
        RestClient.post(app.event_webhook, { events: events }.to_json, { content_type: :json })
      rescue RestClient::BadRequest
      end

      query.update_all(reported: true)
    end
  end
end
