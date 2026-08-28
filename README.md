# Clearsky

A weather forecast application built with Ruby 3.4 and Rails 8.1. Enter any US address to get
current conditions and a 7-day extended forecast. Results are cached by zip code for
30 minutes.

---

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Rails 8 |
| Database | PostgreSQL |
| Cache Store | Solid Cache (PostgreSQL-backed) |
| Weather API | WeatherAPI.com |
| HTTP Client | Faraday |
| Frontend | Turbo Frames + Tailwind CSS |
| Testing | RSpec + WebMock + VCR |
| Rate Limiting | Rack::Attack |

---

## Architecture

The app is organized around a strict separation of concerns. The controller is thin —
it validates input and delegates to a service object. All external API communication,
caching, and business logic live in purpose-built classes.

```
ForecastsController
  └── ForecastQuery                     # validates + normalizes address input
  └── ForecastService                   # orchestrates geocoding, weather, and cache
        ├── Geocoding::WeatherApiGeocoder  # address → Location value object
        ├── Weather::WeatherApiProvider    # Location → Forecast value object
        └── Rails.cache                    # read/write keyed by zip code
```

### Object Decomposition

| Class | Responsibility |
|---|---|
| `ForecastsController` | HTTP boundary. Params in, response out. No business logic. |
| `ForecastQuery` | Validates and normalizes the raw address input. |
| `ForecastService` | Orchestrates geocoder, weather provider, and cache. Returns `{ forecast:, cached: }`. |
| `Geocoding::Base` | Abstract geocoding interface (Strategy pattern). |
| `Geocoding::WeatherApiGeocoder` | Resolves address → `Location` via WeatherAPI. Cached 24 hours. |
| `Weather::Base` | Abstract weather provider interface (Strategy pattern). |
| `Weather::WeatherApiProvider` | Fetches forecast from WeatherAPI via Faraday. Handles timeouts and retries. |
| `Location` | Immutable value object. Holds lat, lon, zip, city, region. |
| `Forecast` | Immutable value object. Wraps API response. Exposes current temp, high/low, extended forecast days. |
| `Forecast::Day` | Immutable value object. Represents a single day in the extended forecast. |
| `Forecast::NullForecast` | Null Object. Returned on API failure. Prevents nil checks in the view. |
| `ForecastPresenter` | Formats `Forecast` data for display. Exposes cache indicator. |

### Design Patterns

- **Strategy** — `Weather::Base` and `Geocoding::Base` define interfaces; concrete implementations are injected into `ForecastService`, making providers swappable without touching orchestration logic.
- **Service Object** — `ForecastService` encapsulates the forecast use case. One entry point, one responsibility.
- **Value Object** — `Forecast`, `Location`, and `Forecast::Day` are immutable and equal by value. Safe to cache, trivial to test.
- **Null Object** — `Forecast::NullForecast` eliminates nil checks in the view layer.
- **Presenter** — `ForecastPresenter` keeps formatting logic out of views and helpers.

---

## Caching Strategy

Forecast results are cached by **zip code** for 30 minutes using Solid Cache (PostgreSQL-backed).
Caching at the zip level maximizes hit rate — many distinct addresses resolve to the same zip.
Geocoding results are cached separately for 24 hours.

| Data | Cache Key | TTL |
|---|---|---|
| Forecast | `clearsky:forecast:v1:{zip}` | 30 minutes |
| Geocoding | `clearsky:geocoding:v1:{normalized_address}` | 24 hours |

Cache keys are versioned (`v1`) so a data structure change can be invalidated by bumping
the version without a manual cache flush. `race_condition_ttl` is set to prevent cache
stampedes under concurrent load.

A **cache indicator** is displayed in the UI when a result is served from cache.

---

## Security

- **API credentials** stored in Rails encrypted credentials — never in `.env` or source control
- **Input validation** handled by `ForecastQuery` before any external call is made
- **Rate limiting** via Rack::Attack — 10 requests/minute per IP, returns `429` when exceeded
- **CSRF protection** enabled by default; Turbo handles token injection automatically

---

## Future Considerations

| Improvement | Notes |
|---|---|
| Circuit breaker | Add Stoplight or Semian if WeatherAPI reliability becomes a concern |
| Background geocoding | Offload to Solid Queue if geocoding latency impacts UX |
| Multi-provider fallback | Architecture already supports it via the Strategy pattern |
| Celsius / Fahrenheit toggle | Straightforward addition once core flow is stable |
| Observability | OpenTelemetry integration for production APM |

---

## Setup

### Prerequisites

- Ruby 3.4+
- PostgreSQL 14+
- A free [WeatherAPI.com](https://www.weatherapi.com) account and API key

### Install

```bash
git clone https://github.com/absarora/clearsky.git
cd clearsky
bundle install
```

### Configure Credentials

```bash
EDITOR="code --wait" rails credentials:edit
```

Add the following:

```yaml
weather_api:
  key: YOUR_WEATHERAPI_KEY_HERE
```

### Database

```bash
rails db:create db:migrate
```

### Run

```bash
bin/dev
```

---

## Tests

```bash
# Full suite
bundle exec rspec

# Single file
bundle exec rspec spec/services/forecast_service_spec.rb

# With documentation output
bundle exec rspec --format documentation
```

---

## Health Check

`GET /health` returns `200 OK`. Used by load balancers to verify the app is running.
