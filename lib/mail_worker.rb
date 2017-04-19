# For Sidekiq
class MailWorker
  include Sidekiq::Worker

  def perform(email_id)
    email = Email.find(email_id)
    email.deliveries.each do |delivery|
      OutgoingDelivery.new(delivery).send
    end
  end
end
