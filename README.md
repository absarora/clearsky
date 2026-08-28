# Clearsky

A weather forecast application built with Ruby 3.4 and Rails 8.1. Enter any US address to get
current conditions and a 7-day extended forecast. Results are cached by zip code for
30 minutes.

---

## A Note on Development Tooling

This project was developed with **Claude Code** as a productivity tool — used for
architectural discussion, code generation, and iterative refinement. All architectural
decisions, design patterns, and implementation choices were made and reviewed by the
developer.

---

## Tech Stack

| Layer | Choice | Rationale |
|---|---|---|
| Framework | Rails 8 | Current release; ships Solid Cache as a first-party default |
| Database | PostgreSQL | Enterprise standard |
| Cache Store | Solid Cache (PostgreSQL-backed) | First-party Rails 8 cache; no Redis dependency |
| Weather API | WeatherAPI.com | Single call returns current + 7-day forecast; clean JSON; 1M free calls/month |
| HTTP Client | Faraday + faraday-retry | Middleware stack with built-in timeout and retry support |
| Frontend | Turbo Frames + Tailwind CSS | Standard Rails 8 stack; no custom JavaScript |
| Testing | RSpec + WebMock + VCR | Industry standard; deterministic specs with no live API calls in CI |
| Rate Limiting | Rack::Attack | Protects WeatherAPI quota; 10 requests/minute per IP |

---

## Architecture

The app is organized around a strict separation of concerns. The controller is intentionally
thin — it validates input and delegates to a service object. All external API communication,
caching, and business logic live in purpose-built classes.

```
ForecastsController
  └── ForecastService                      # orchestrates weather provider and cache
        ├── Weather::WeatherApiProvider    # zip → Forecast value object via WeatherAPI
        └── Rails.cache                    # read/write keyed by zip code (Solid Cache)
```

### Object Decomposition

| Class | Responsibility |
|---|---|
| `ForecastsController` | HTTP boundary. Validates zip input, delegates to service, assigns presenter. |
| `ForecastService` | Orchestrates provider and cache. Returns `Forecast` or `NullForecast`. |
| `Weather::WeatherApiProvider` | Fetches forecast from WeatherAPI via Faraday. Handles timeouts and retries. |
| `Location` | Immutable value object. Holds zip, city, region from the API response. |
| `Forecast` | Immutable value object. Wraps full API response. Exposes current temp, high/low, extended days. |
| `Forecast::Day` | Immutable value object. Represents one day in the extended forecast. |
| `Forecast::NullForecast` | Null Object. Returned on API failure. Eliminates nil checks in the view. |
| `ForecastPresenter` | Formats `Forecast` data for display. Exposes cache indicator. |
| `Clearsky::WeatherApiError` | Typed error raised on any API or network failure. |

### Design Patterns

**Service Object** — `ForecastService` encapsulates the forecast use case. One entry point,
one responsibility. The controller never contains business logic.

**Value Object** — `Forecast`, `Location`, and `Forecast::Day` are immutable and equal by
value. Frozen on initialization. Safe to cache, trivial to test.

**Null Object** — `Forecast::NullForecast` implements the same interface as `Forecast` with
safe defaults. The view renders it without nil checks or type inspection.

**Presenter** — `ForecastPresenter` keeps all formatting logic out of views. Views call
presenter methods; they never format data directly.

---

## Caching Strategy

Forecast results are cached by **zip code** for 30 minutes using Solid Cache (PostgreSQL-backed),
shared across all Puma workers. Caching at the zip level maximizes hit rate — many addresses
share the same zip code.

| Data | Cache Key | TTL |
|---|---|---|
| Forecast | `clearsky:forecast:v1:{zip}` | 30 minutes |

Cache keys are versioned (`v1`) — bumping to `v2` invalidates stale entries without a manual
cache flush. `race_condition_ttl` prevents cache stampedes under concurrent load.

A **cache indicator badge** is displayed in the UI when a result is served from cache.

---

## Address Input

Input is scoped to **US zip codes**, which WeatherAPI accepts natively as the location
parameter and uses to return precise forecast data. This eliminates a separate geocoding
service dependency while satisfying the zip-level cache granularity requirement.

A production system requiring free-form street address input would add a dedicated geocoding
service (Google Maps Geocoding API or Geoapify) upstream of the weather provider. The
architecture supports this cleanly — `ForecastService` accepts an injected provider, making
the geocoding step addable without modifying orchestration logic.

---

## Security

- **API credentials** stored in Rails encrypted credentials — never in `.env` or source control
- **Input validation** in the controller — blank zip redirects before any service call
- **Rate limiting** via Rack::Attack — 10 requests/minute per IP, returns `429` when exceeded
- **Typed errors** — `WeatherApiError` prevents broad `StandardError` rescues
- **API response validation** — `fetch` calls on response keys raise `WeatherApiError` on
  unexpected shape rather than propagating `KeyError` or `NoMethodError`
- **CSRF protection** enabled by default; Turbo handles token injection automatically
- **WebMock** disables all external HTTP in the test suite — no accidental live API calls in CI

---

## Future Considerations

| Improvement | Notes |
|---|---|
| Free-form address input | Add Geoapify or Google Maps Geocoding upstream of `WeatherApiProvider` |
| Circuit breaker | Add Stoplight if WeatherAPI reliability becomes a concern |
| Celsius / Fahrenheit toggle | Straightforward addition once core flow is stable |
| Observability | OpenTelemetry for production APM |
| Background geocoding | Offload to Solid Queue if geocoding latency impacts UX |

---

## Setup

### Prerequisites

- Ruby 3.4.7
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
rails db:prepare
```

Sets up the PostgreSQL databases and loads the Solid Cache schema.
Required for caching to work — skipping this will cause a `PG::UndefinedTable`
error on the first cached request.

### Run

```bash
bin/dev
```

Visit `http://localhost:3000`, enter a US zip code, and get the forecast.

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

All external HTTP calls are stubbed via WebMock and VCR cassettes. No API key or network
connection is required to run the test suite.

---

## Health Check

`GET /health` returns `200 OK`. Used by load balancers to verify the app is running.

---

*Ruby on Rails 8 · WeatherAPI.com · Solid Cache · Turbo · Tailwind CSS*