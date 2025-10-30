# frozen_string_literal: true

if Rails.env.production?
  # Provided that trusted users use an HTTP request param named skip_rack_attack
  # with this you can perform apache benchmark test like this:
  # ab -n 2000 -c 20 'https://decidim.url/?skip_rack_attack=some-secret'
  Rack::Attack.safelist("bypass active storage") do |request|
    # skip rails active storage routes
    request.path.start_with?("/rails/active_storage")
  end

  Rack::Attack.safelist("bypass authenticated users") do |request|
    # skip logged users
    request.env.dig("rack.session", "warden.user.user.key").present?
  end

  Rack::Attack.safelist("bypass with secret param") do |request|
    # Requests are allowed if the return value is truthy
    request.params["skip_rack_attack"] == Rails.application.secrets.rack_attack_skip
  end

  allowed_ips = ENV.fetch("RACK_ATTACK_ALLOWED_IPS", nil)
  if allowed_ips.present?
    allowed_ips.split(",").each do |ip|
      Rack::Attack.safelist_ip(ip)
    end
  end
end
