class EventWebhookWorker
  include Sidekiq::Worker
  def perform
    App.where.not(event_webhook: nil).find_each do |app|
      query = app.deliveries.includes(:address).where(reported: false).limit(500).where.not(status: ['sent', 'not_sent'])
      if app.event_webhook =~ URI::regexp
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
      end
      query.update_all(reported: true)
    end
  end
end
