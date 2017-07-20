class PostfixController < ApplicationController
  skip_filter :authenticate_admin!

  skip_before_action :verify_authenticity_token

  def create
    mail = Mail.new(request.raw_post)
    to_address = mail[:to].addrs.first
    if to_address.address =~ /bounce\+(.+)@alpha.huaxing.com/
      verifier = ActiveSupport::MessageVerifier.new(Rails.application.secrets.secret_key_base)
      id = verifier.verify($1)
      handle_bounce(mail, id)
    else
      domain = to_address.domain
      app = App.find_by(from_domain: domain)
      head :not_found if app.blank? || app.inbound_webhook.blank?
      body = request.raw_post
      body = body.encode(Encoding.find('UTF-8'), { invalid: :replace, undef: :replace, replace: '' })
      InboundWebhookWorker.perform_async(app.inbound_webhook, body)
      head :ok
    end
  end

  private

  def handle_bounce(mail, id)
    return head :bad_request if id.blank?

    delivery = Delivery.find_by(id: id)
    return head :bad_request if delivery.blank?

    PostfixLogLine.create(delivery: delivery, time: mail.date || Time.current, relay: :local,
                          delay: '0', delays: '0', dsn: '5.0.0',
                          extended_status: (mail.html_part || mail.text_part || mail).body.decoded)

    key = "bounce-from-email-#{delivery.email}"
    count = $redis.incr(key)
    $redis.expire(key, 3600 * 24)
    if count >= 5
      BlackList.create(team_id: delivery.app.team_id, address: delivery.address, caused_by_delivery: delivery)
      $redis.del(key)
    end
    head :ok
  end
end
