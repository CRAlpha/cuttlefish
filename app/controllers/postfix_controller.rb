class PostfixController < ApplicationController
  skip_filter :authenticate_admin!

  skip_before_action :verify_authenticity_token

  def create
    mail = Mail.new(request.raw_post)
    to_address = mail[:to].addrs.first

    domain = to_address.domain
    app = App.find_by(from_domain: domain)
    return head :not_found if app.blank? || app.inbound_webhook.blank?
    body = request.raw_post
    body = body.encode(Encoding.find('UTF-8'), { invalid: :replace, undef: :replace, replace: '' })
    InboundWebhookWorker.perform_async(app.inbound_webhook, body)
    head :ok
  end
end
