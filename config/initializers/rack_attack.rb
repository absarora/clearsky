# config/initializers/rack_attack.rb
#
# Rack::Attack provides request throttling to protect the WeatherAPI quota
# from abuse and prevent denial-of-service against the cache layer.
#
# Blocked requests receive a 429 Too Many Requests response.
#
# See https://github.com/rack/rack-attack

class Rack::Attack
  # Throttle forecast requests to 10 per minute per IP address.
  # This is intentionally generous for legitimate use while protecting
  # against automated abuse.
  throttle("forecasts/ip", limit: 10, period: 60.seconds) do |request|
    request.ip if request.path == "/forecast" && request.get?
  end

  # Return a 429 with a plain text body when a request is throttled.
  self.throttled_responder = lambda do |request|
    [
      429,
      { "Content-Type" => "text/plain" },
      ["Too many requests. Please wait a moment before trying again."]
    ]
  end
end
