require 'ostruct'
require 'eventmachine'
require 'mail'
require File.expand_path File.join(File.dirname(__FILE__), 'email_data_cache')
require File.expand_path File.join(File.dirname(__FILE__), "..", 'config', 'initializers', 'sidekiq')
require File.expand_path File.join(File.dirname(__FILE__), 'mail_worker')
require File.expand_path File.join(File.dirname(__FILE__), "..", "app", "models", "app")
require File.expand_path File.join(File.dirname(__FILE__), "..", "app", "models", "email")
require File.expand_path File.join(File.dirname(__FILE__), "..", "app", "models", "address")
require File.expand_path File.join(File.dirname(__FILE__), "..", "app", "models", "delivery")

class CuttlefishSmtpServer
  attr_accessor :connections

  def initialize
    @connections = []
  end

  def start(host = 'localhost', port = 1025)
    trap("TERM") {
      puts "Received SIGTERM"
      stop
    }
    trap("INT") {
      puts "Received SIGINT"
      stop!
    }
    @server = EM.start_server host, port, CuttlefishSmtpConnection do |connection|
      connection.server = self
      @connections << connection
    end
  end

  # Gracefull shutdown
  def stop
    puts "Stopping server gracefully..."
    EM.stop_server @server

    unless wait_for_connections_and_stop
      # Still some connections running, schedule a check later
      EventMachine.add_periodic_timer(1) { wait_for_connections_and_stop }
    end
  end

  def wait_for_connections_and_stop
    if @connections.empty?
      EventMachine.stop
      true
    else
      false
    end
  end

  # Forceful shutdown
  def stop!
    puts "Stopping server quickly..."
    if @server
      EM.stop_server @server
      @server = nil
    end
    exit
  end
end

class CuttlefishSmtpConnection < EM::P::SmtpServer
  attr_accessor :server

  def initialize
    super
    self.parms = CuttlefishSmtpConnection.default_parameters
  end

  def self.default_parameters
    parameters = {
      auth: :required,
    }
    # Don't use our own SSL certificate in development
    unless Rails.env.development?
      parameters[:starttls_options] = {
        cert_chain_file: Rails.configuration.cuttlefish_domain_cert_chain_file,
        private_key_file: Rails.configuration.cuttlefish_domain_private_key_file
      }
      parameters[:starttls] = :required
    end
    parameters
  end

  def unbind
    server.connections.delete(self)
  end

  def get_server_domain
    Rails.configuration.cuttlefish_domain
  end

  def get_server_greeting
    "Cuttlefish SMTP server waves its arms and tentacles and says hello"
  end

  def receive_sender(sender)
    current.sender = sender
    true
  end

  def receive_recipient(recipient)
    current.recipients = [] if current.recipients.nil?
    current.recipients << recipient
    true
  end

  def receive_message
    current.received = true
    current.completed_at = Time.now

    # TODO No need to capture current.sender, current.received, current.completed_at
    # because we're not passing it on
    #
    # Before we send current.data to MailWorker we need to deal with the encoding
    # because before it gets stored in redis it needs to be serialised to json
    # which requires a conversion to utf8
    # It comes in with unknown encoding - so let's encode it as base64
    @email = nil

    ActiveRecord::Base.transaction do
      from = Mail.new(current.data).from.first
      @email = Email.create!(from: from,
                            to: current.recipients.map { |t| t.match("<(.*)>")[1] },
                            data: current.data,
                            app_id: current.app_id)
      MailWorker.perform_async(email.id)
    end

    @current = OpenStruct.new

    @email.presence
  end

  def receive_plain_auth(user, password)
    # This currently will only check the authentication if it's sent
    # In other words currently the authentication is optional
    app = App.where(smtp_username: user).first
    if app && app.smtp_password == password
      current.app_id = app.id
      true
    else
      false
    end
  end

  def receive_data_command
    current.data = ""
    true
  end

  def receive_data_chunk(data)
    current.data << data.join("\n")
    true
  end

  def current
    @current ||= OpenStruct.new
  end

  def process_data_line ln
    if ln == "."
      if @databuffer.length > 0
        receive_data_chunk @databuffer
        @databuffer.clear
      end

      d = receive_message

      success_message =
        if @email
          "created with id #{@email.id}"
        else
          "created"
        end

      succeeded = proc {
        send_data "250 Message #{success_message}\r\n"
        reset_protocol_state
      }
      failed = proc {
        send_data "550 Message rejected\r\n"
        reset_protocol_state
      }

      if d.respond_to?(:set_deferred_status)
        d.callback(&succeeded)
        d.errback(&failed)
      else
        (d ? succeeded : failed).call
      end

      @state.delete :data
    else
      # slice off leading . if any
      ln.slice!(0...1) if ln[0] == ?.
      @databuffer << ln
      if @databuffer.length > @@parms[:chunksize]
        receive_data_chunk @databuffer
        @databuffer.clear
      end
    end
  end
end
