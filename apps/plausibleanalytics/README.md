# Plausible Analytics On Your Tidbyt

An app for the [Tidbyt](https://tidbyt.com) that uses the [plausible.io stats API](https://plausible.io/docs/stats-api) to display metrics about your website.

## Features

1. Each instance of the app shows a single metric (all metrics are supported)
2. The time period of the metric is fully customizable
3. An optional historical chart of that metric can be shown (and the chart's time period is customizable as well)
4. Your site's favicon is fetched and displayed automatically (or a custom path can be set)

Metrics are fetched every 10 minutes.
Favicons are fetched once per day.

## Options

The following options can be set via the Schema, or passed in via the `pixlet render` command:

| Option Key           | Accepted Value                                                             | Required | Description                                                                                                                                                                 |
| -------------------- | -------------------------------------------------------------------------- | -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `domain`             | Any String                                                                 | YES      | The domain of the website to display. The scheme "http://" and "www" are not needed.                                                                                        |
| `plausible_api_key`  | Any String                                                                 | YES      | Generate a new API key at https://plausible.io/settings#api-keys                                                                                                            |
| `metric`             | String: `pageviews`, `visitors`, `bounce_rate`, `visit_duration`, `visits` | NO       | The metric to display. Defaults to `pageviews`                                                                                                                              |
| `time_period`        | String: `day`, `7d`, `30d`, `month`, `6mo`, `12mo`, `custom`               | NO       | The time period for the stats to display. Defaults to `day`. **NOTE** `custom` will get the metric value count for all time                                                 |
| `chart_time_period`  | String: `7d`, `30d`, `month`, `6mo`, `12mo`                                | NO       | Defaults to `7d`. The historical time period for the chart display                                                                                                          |
| `favicon_path`       | Any String                                                                 | NO       | The relative path to the favicon file to display eg. `/favicon/favicon.png`                                                                                                 |
| `should_show_chart`  | Bool                                                                       | NO       | Defaults to `true`. Controls the visibility of the historical chart                                                                                                         |

## Screenshots

![Screenshot](screenshot.png)

---

![Store screen](screenshot-store.gif)

(As seen when adding in the app)

---

![No Chart](screenshot-no-chart.gif)

(When the chart is disabled)

---

![Animated Stat](screenshot-bounce-rate.gif)

(When a stat's name is longer and needs to scroll)

---

![Error: no API key](screenshot-missing-key.gif)

(Error: No API key)

---

![Error: invalid domain](screenshot-invalid-domain.gif)

(Error: No/Invalid domain)
