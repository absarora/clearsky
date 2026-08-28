# config/routes.rb

Rails.application.routes.draw do
  # ─── Health Check ─────────────────────────────────────────────────────────
  #
  # Built-in Rails 8 health check endpoint. Returns 200 if the app boots
  # without exceptions, 500 otherwise. Used by load balancers and uptime
  # monitors to verify the app is live.
  get "health" => "rails/health#show", as: :rails_health_check

  # ─── Forecast ─────────────────────────────────────────────────────────────
  #
  # Root renders the address input form.
  # GET /forecast accepts an address param and returns forecast results.
  root "forecasts#index"
  get "/forecast", to: "forecasts#show", as: :forecast
end
