# Muni Departures

Display real-time San Francisco Muni bus and rail departure times on your Tidbyt.

![Muni Departures App](https://via.placeholder.com/64x32/000000/FFFFFF?text=MUNI)

## Features

- **Real-time departures** for two Muni lines simultaneously
- **Direction indicators** showing inbound (IN) or outbound (OUT) services
- **Color-coded badges** matching official Muni line colors
- **Scrolling stop names** for long station names
- **Live updates** with 30-second refresh intervals

## Setup

### 1. Get Your Free API Key

1. Visit [511.org/developers](https://511.org/developers)
2. Create a free account
3. Generate an API key
4. Copy the API key for use in step 3

### 2. Find Your Stop Codes

Muni stop codes are 4-5 digit numbers found on bus stop signs and station platforms:

- Look for small numbers on the bus stop sign
- Or use the [511.org Trip Planner](https://511.org/transit) to find stop codes
- Example stop codes: `16995` (Market & Castro), `13128` (Powell Station)

### 3. Configure the App

1. Install the Muni Departures app on your Tidbyt
2. Enter your 511.org API key
3. For each line:
   - Select the transit line (F, J, 38, etc.)
   - Enter the stop code
4. Save your configuration

## Line Types

The app supports all Muni service types:

### Rail Lines
- **F** - Market & Wharves (Yellow circle)
- **J** - Church (Orange circle)
- **K** - Ingleside (Blue circle)
- **L** - Taraval (Purple circle)
- **M** - Ocean View (Green circle)
- **N** - Judah (Blue circle)
- **T** - Third Street (Red circle)

### Bus Lines
- All numbered bus routes (1, 5, 38, etc.)
- Express routes (1X, 5R, 38R, etc.)
- Displayed with red badges

### Cable Cars
- **C** - California Line
- **PH** - Powell-Hyde
- **PM** - Powell-Mason

## Display Format

```
[BADGE] STOP NAME
        [DIR] [TIMES]
```

Example:
```
🔴 38  GEARY / FILLMORE
       OUT 5 12 18

🟡 J   CHURCH / 24TH ST  
       IN Due 8 15
```

## Troubleshooting

### "API Key Required" Message
- Double-check your API key is entered correctly
- Ensure your 511.org account is active

### "No Data" Message
- Verify the stop code is correct
- Check if the selected line serves that stop
- Some stops may have limited weekend/evening service

### Long Stop Names
- Stop names automatically scroll if they're too long
- Ampersands (&) are displayed as slashes (/) for better readability

## Privacy & Rate Limits

- Your API key stays private and is only used by your Tidbyt
- Each user gets their own 511.org rate limits
- The app caches stop names for 5 minutes to reduce API calls
- Real-time data refreshes every 30 seconds

## Credits

Developed by **westcoasttank** for the Tidbyt community.

Data provided by [511.org](https://511.org) - San Francisco Bay Area's official transit information service.
