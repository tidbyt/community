# HomeGame

A Tidbyt applet that displays upcoming college football game information with home/away indicators, countdown timers, and live scores.

## Features

- **Team Selection**: Choose from 76+ popular college football teams via dropdown
- **Dynamic Styling**: Game-day solid backgrounds vs. non-game-day colored text
- **Live Countdown**: Real-time countdown timer on game day
- **Live Scores**: Quarter-by-quarter scoring with period indicators (Q1-Q4, OT, FINAL)
- **Home/Away Indicator**: Visual distinction between home (red) and away (green) games
- **Timezone Support**: Location-based timezone detection

## Setup

### Prerequisites

1. Install [Pixlet](https://github.com/tidbyt/pixlet)
2. Ensure pixlet is in your PATH
3. Login to your Tidbyt account:
   ```bash
   pixlet login
   ```
4. Find your device ID:
   ```bash
   pixlet devices
   ```

### Configuration

The app uses a user-friendly configuration interface:

- **Team Selection**: Choose from dropdown of popular teams (SEC, Big Ten, Big 12, ACC, Pac-12, Independents)
- **Custom Teams**: Select "Other (Enter Team ID)" to enter any ESPN team ID
- **Location**: Use location picker for automatic timezone detection

## Local Development

### Live Preview

Run the app locally with interactive configuration:

```bash
pixlet serve homegame.star
```

View at: http://localhost:8080

Configure your team and location in the web interface.

### Manual Testing

Render with specific configuration:

```bash
# Texas A&M example
pixlet render homegame.star team_dropdown=245

# Alabama example
pixlet render homegame.star team_dropdown=333
```

## Deployment

### Quick Deploy (Recommended)

Use the provided push scripts for one-command deployment:

**Windows (PowerShell)**:
```powershell
.\push_to_tidbyt.ps1 -DeviceId "your-device-id"
```

**Linux/Mac (Bash)**:
```bash
./push_to_tidbyt.sh your-device-id
```

### Advanced Options

**Push with custom team**:
```powershell
# Windows
.\push_to_tidbyt.ps1 -DeviceId "abc123" -TeamId "333"

# Linux/Mac
./push_to_tidbyt.sh abc123 --team-id 333
```

**Push to background rotation**:
```powershell
# Windows
.\push_to_tidbyt.ps1 -DeviceId "abc123" -Background

# Linux/Mac
./push_to_tidbyt.sh abc123 --background
```

**View all options**:
```powershell
# Windows
Get-Help .\push_to_tidbyt.ps1 -Full

# Linux/Mac
./push_to_tidbyt.sh --help
```

### Manual Deployment

If you prefer manual control:

1. **Render the app**:
   ```bash
   pixlet render homegame.star team_dropdown=245 --output homegame.webp
   ```

2. **Push to device**:
   ```bash
   pixlet push <device-id> homegame.webp --installation-id homegame
   ```

## Display States

The app has three distinct display modes:

1. **Future Game** (non-game day):
   - Date and time of next game
   - Colored text on black background
   - No border

2. **Countdown** (game day, pre-kickoff):
   - Live countdown timer (hours/minutes until kickoff)
   - Kickoff time displayed
   - Solid red (home) or green (away) background

3. **In Progress** (live game):
   - Current score (our team vs opponent)
   - Period indicator (Q1, Q2, Q3, Q4, OT, FINAL)
   - Yellow text for active quarters, white for final

## Testing

The app includes comprehensive integration tests. See [DEVELOPMENT.md](DEVELOPMENT.md) for testing documentation.

Run tests:
```powershell
cd tests
.\run_integration_tests.ps1
```

## Popular Team IDs

| Conference | Team | ID |
|------------|------|-----|
| SEC | Alabama | 333 |
| SEC | Texas A&M | 245 |
| SEC | Georgia | 61 |
| SEC | LSU | 99 |
| Big Ten | Ohio State | 194 |
| Big Ten | Michigan | 130 |
| Big Ten | Penn State | 213 |
| Big 12 | Oklahoma State | 197 |
| Big 12 | TCU | 2628 |
| ACC | Clemson | 228 |
| ACC | FSU | 52 |
| Independent | Notre Dame | 87 |

Full list of 76+ teams available in the dropdown selector.

## Troubleshooting

### Push fails with authentication error
- Run `pixlet login` to authenticate
- Or get API token from https://tidbyt.com/settings/account
- Use `--api-token` flag with push script

### Can't find device ID
- Run `pixlet devices` to list all your Tidbyt devices
- Copy the device ID (hexadecimal string)

### Team not showing games
- Verify team ID at ESPN.com (check URL on team page)
- Try alternate endpoint: http://site.api.espn.com/apis/site/v2/sports/football/college-football/teams/[TEAM_ID]

### Wrong timezone
- Use location picker in configuration UI
- Timezone is automatically extracted from location

## Documentation

- [REQUIREMENTS.md](REQUIREMENTS.md) - Detailed requirements and specifications
- [DEVELOPMENT.md](DEVELOPMENT.md) - Development workflow, linting, and testing
- [todo.md](todo.md) - Planned improvements and roadmap

## Author

tscott98

## License

See repository root for license information.
