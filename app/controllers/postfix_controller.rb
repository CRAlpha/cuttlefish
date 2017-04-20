class PostfixController < ApplicationController
  skip_filter :authenticate_admin!

  skip_before_action :verify_authenticity_token

  def create
    mail = Mail.new(request.raw_post)
    to = mail.to.first
    if to.present? && to =~ /bounce\+(.+)@cf.zhaoalpha.com/
      verifier = ActiveSupport::MessageVerifier.new(Rails.application.secrets.secret_key_base)

      id = verifier.verify($1)
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
    else
      head :bad_request
    end
  end
end
