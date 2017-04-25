class Filters::Tracking < Filters::Mail
  attr_accessor :tracking_domain, :using_custom_tracking_domain

  def initialize(options)
    @tracking_domain = options[:tracking_domain]
    @using_custom_tracking_domain = options[:using_custom_tracking_domain]
  end

  # Hostname to use for the open tracking image or rewritten link
  def host
    Rails.env.development? ? "localhost:3000" : tracking_domain
  end

  def protocol
    'http'
  end
end
