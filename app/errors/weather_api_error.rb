# app/errors.rb
#
# Application-level error classes for Clearsky.
#
# Typed errors allow callers to rescue specific failure modes
# rather than broad StandardError catches.

# Raised when WeatherAPI returns an unexpected response or is unreachable.
class WeatherApiError < StandardError; end
