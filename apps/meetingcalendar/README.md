# Meeting Calendar

Today's timed events and live meetings on a 64×32 Tidbyt. This community app runs on Tidbyt's hosted runtime: no Tidbyt Plus, external server, or separate hosting subscription is required.

![Today's events](meeting_calendar.gif) ![Simultaneous meetings](meetings.gif)

## Connect a calendar

Add **Meeting Calendar** in the Tidbyt mobile app and paste **one calendar subscription URL** in its settings. Use an ICS feed, not a calendar webpage or event invitation. Additional installations can show additional calendars; their busy-time calculations are independent.

- **iCloud:** open the calendar's sharing options in iCloud Calendar, enable **Public Calendar**, and copy its `webcal://…icloud.com/published/…` link. The app converts `webcal://` to HTTPS.
- **Google Calendar:** on the web, open **Settings → Settings for my calendars → Integrate calendar → Secret address in iCal format**. A public iCal address also works for an already-public calendar. Workspace administrators may disable these options.
- **Outlook:** on the web, open **Settings → Calendar → Shared calendars → Publish a calendar**. Publish with event-detail access and copy the **ICS** link. A busy-only feed cannot supply meeting titles or identify calls. Organization policy may prevent publishing.

Supported endpoints: iCloud `/published/` feeds, `calendar.google.com/calendar/ical/`, and `/owa/calendar/` on `outlook.live.com`, `outlook.office.com`, and `outlook.office365.com`. There is no Google/Microsoft sign-in or support for feeds requiring an authenticated browser session.

## Settings and behavior

All settings live in the Tidbyt mobile app. Leave the optional timezone override blank to use the device timezone, or enter an IANA name such as `America/New_York`. This timezone also interprets calendar times that omit their own timezone.

Defaults: Midnight calendar theme, Red alert meeting theme, 12-hour time, call badges enabled, three seconds per normal event, 20 normal events, and **LIVE**. Controls also offer Ocean/Forest, Amber/Magenta, 24-hour time, **ON AIR**, one to ten seconds per event in quarter-second increments, and one to 20 events.

- Remaining timed events today rotate chronologically, including events underway. All-day events are excluded, including recurring and multi-day all-day events.
- Zoom, Google Meet/Hangouts, Teams, FaceTime, Webex, Slack Huddles, Discord, Jitsi, Whereby, GoTo, and RingCentral are recognized in URL, location, Apple structured location, and description fields.
- Scheduled calls produce a meeting screen **during this app's normal turn in rotation**. The app does not detect whether you joined the call or interrupt other apps.
- Simultaneous calls show their count and page through their titles. Busy-until time merges overlapping and directly adjacent busy events in this calendar. Ordinary transparent events do not extend busy time; recognized calls do.
- Full playback is requested: 20 normal events at three seconds each can occupy one minute. Active titles are capped at 240 printable characters; the compact single-call layout displays the first two lines.
- **Display calendar** off returns no image on the next render. A successfully fetched calendar with no remaining events also returns no image. The installation remains configured for future events.

### Timing and failures

Successful feeds are cached for 60 seconds. Tidbyt controls render and delivery timing; calendar providers can add publication delay. No exact refresh interval or foreground takeover is promised.

Graphics request expiration at the next relevant meeting/event/day boundary or after five minutes, whichever is sooner. Expiration does not force a refresh; during an outage the calendar may disappear until an update arrives. Hosted full-playback, empty-state and expiration behavior must be verified on a physical device. Local `pixlet push` does not establish those hosted contracts.

HTTP errors and invalid calendars display a short error. Pixlet 0.34.0 cannot catch network/DNS/TLS exceptions or body-read failures in Starlark; these abort rendering and the previous graphic's expiration provides the fallback. No stale-feed fallback is used to claim LIVE status.

## Compatibility

Supports unfolded/escaped ICS text; start/end/duration; daily, weekly, monthly and yearly recurrence; intervals, counts, end dates, weekday/month-day/month filters, positional rules, additional/excluded dates, and individual recurrence changes/cancellations. UTC, floating times, IANA timezones, recognized Windows names, and supported embedded `VTIMEZONE` rules are handled. Unresolved timezones produce an error.

Expansion covers today and a 21-day future horizon, including earlier ongoing events. Input is limited to 10 MB; expansion permits 100,000 candidate-day scans per render, 2,000 dates per series, and 10,000 output events. Active displays are limited to 150 title pages (five minutes). Exceeded limits produce an error instead of a partial schedule.

Subdaily recurrence, `RANGE=THISANDFUTURE`, deprecated `EXRULE`, `RDATE;VALUE=PERIOD`, selectors such as `BYHOUR`/`BYWEEKNO`/`BYYEARDAY`, and embedded timezone `EXDATE`/`COUNT` rules are rejected. Compatibility means this documented ICS subset, not every possible calendar export.

## Privacy and revocation

The subscription link grants read access to whoever possesses it. Tidbyt stores it as installation configuration, downloads the calendar, and caches the response. The app author operates no server and collects no link. App code does not print URLs, feed bodies, or event details; Tidbyt runtime diagnostics are outside its control.

Use a dedicated calendar if appropriate. Never include real feed links or calendar data in public issues, logs, or previews. Removing/disabling the app does **not** revoke the feed or immediately erase cached graphics.

- **iCloud:** disable **Public Calendar**; copy the current link again when reconnecting.
- **Google:** reset the **Secret address in iCal format** and update any installations using it. For a public calendar, revoke public sharing if intended.
- **Outlook:** **Unpublish** the calendar; publish again and obtain its current ICS link when reconnecting.

## Development and backlog

Use **Pixlet v0.34.0**, matching the community repository's pin. Run `pixlet serve meetingcalendar` or `pixlet check meetingcalendar` from the parent directory; the directory form loads all local Starlark modules. Python/Node test tooling is not required in production. Reproducible tests and synthetic previews live in [the source project](https://github.com/tlambrou/tidbyt-calendar/tree/codex/meeting-calendar-community).

Optional foreground takeover and Siri/Apple Watch controls are reserved for a separate future user-hosted integration. Multi-calendar aggregation and Google/Microsoft OAuth are also outside this release; there are no placeholder settings for these features.

Provider instructions: [Apple](https://support.apple.com/guide/icloud/share-a-calendar-mm6b1a9479/icloud), [Google](https://support.google.com/calendar/answer/37648), [Microsoft](https://support.microsoft.com/en-us/outlook/share-your-calendar-in-outlook-on-the-web).
