class InternalMailer < Devise::Mailer
  # Hacky way to not try to create cuttlefish app if apps table doesn't yet exist.
  # This can happen when you're doing a "rake db:setup"
  if ActiveRecord::Base.connection.table_exists?(:apps)
    default delivery_method_options: {
      address: Rails.configuration.cuttlefish_domain,
      port: Rails.configuration.cuttlefish_smtp_port,
      user_name: App.cuttlefish.smtp_username,
      password: App.cuttlefish.smtp_password,
      authentication: :plain
    }
  end

  def invitation_instructions(record, token, opts={})
    opts[:subject] = "#{record.invited_by.display_name} invites you to Cuttlefish"
    super
  end
end
