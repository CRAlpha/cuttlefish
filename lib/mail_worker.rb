# For Sidekiq
class MailWorker
  include Sidekiq::Worker

  # We require a base64 encoded version of the raw mail data so that it could
  # succesfully serialised as JSON without knowing what encoding it is (which
  # we don't)
  def perform(email_id)
    ActiveRecord::Base.transaction do
      # Discard the "return path" in sender
      # Take the from instead from the contents of the mail
      # There can be multiple from addresses in the body of the mail
      # but we'll only take the first
      email = Email.find(email_id)

      email.deliveries.each do |delivery|
        OutgoingDelivery.new(delivery).send
      end
    end
  end
end
