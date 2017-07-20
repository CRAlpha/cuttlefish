class TestEmailsController < ApplicationController
  after_action :verify_authorized

  # We're using the simple_format helper below. Ugly but quick by bringing it into the controller
  include ActionView::Helpers::TextHelper

  def new
    authorize :test_email
    @to = current_admin.email_with_name
    @subject = "这是一封来自华兴Alpha的测试邮件"
    @text = <<-EOF
你好,

华兴Alpha <a href="https://alpha.huaxing.com">https://alpha.huaxing.com</a>
    EOF
  end

  # Send a test email
  def create
    authorize :test_email
    app = App.find(params[:app_id])
    authorize app, :show?
    TestMailer.test_email(app,
      from: params[:from], to: params[:to], cc: params[:cc], subject: params[:subject], text: params[:text]).deliver_now

    flash[:notice] = "Test email sent"
    redirect_to deliveries_url
  end
end
