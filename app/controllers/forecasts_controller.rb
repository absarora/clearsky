# app/controllers/forecasts_controller.rb
#
# Thin HTTP boundary for the forecast feature. Validates input,
# delegates to ForecastService, and assigns a presenter to the view.
#
# Contains zero business logic — all orchestration lives in ForecastService.

require_relative "../services/forecast_service"
require_relative "../presenters/forecast_presenter"

class ForecastsController < ApplicationController
  # GET /
  # Renders the address input form.
  def index; end

  # GET /forecast?zip=93721
  # Accepts a zip code, fetches the forecast, and renders the result.
  def show
    zip = params[:zip].to_s.strip

    if zip.blank?
      redirect_to root_path, alert: "Please enter a zip code." and return
    end

    forecast = Clearsky::ForecastService.new.call(zip:)
    @presenter = Clearsky::ForecastPresenter.new(forecast)
  end
end
