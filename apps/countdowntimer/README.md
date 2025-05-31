# Countdown Timer for Tidbyt

A beautiful, customizable countdown timer app for Tidbyt that displays the time remaining until your important events with an animated dot grid visualization.

## Features

### Visual Elements
- **Dynamic countdown display** - Shows days, hours, minutes, and seconds remaining
- **Animated dot grid** - Visual representation of time remaining with smooth filling/unfilling animation
- **Flexible layout** - Toggle any element on/off, with remaining items automatically resizing to fill the display
- **Smart font sizing** - Automatically adjusts text size based on visible elements for optimal readability

### Customization Options
- **Title** - Name your countdown (e.g., "Vacation", "Project Launch", "Birthday")
- **Deadline** - Set any future date and time
- **Dot Granularity** - Choose what each dot represents:
  - Days - Best for long-term countdowns
  - Weeks - Great for month-long events
  - Hours - Perfect for short-term deadlines
  - Minutes - Ideal for very short countdowns
- **Color Customization**:
  - Title color
  - Countdown time color
  - Dot animation color
  - Target date color
- **Visibility Toggles** - Show/hide any element:
  - Title row
  - Countdown time
  - Animated dots
  - Target date

## Display Formats

The countdown intelligently formats the time display:
- **7+ days**: Shows as "7d 23:59:59"
- **Less than 7 days**: Shows as "23:59:59"
- **Time's up**: Displays "TIME'S UP!" with red background

## Animation

The dot grid features a smooth filling animation:
1. Dots progressively light up from left to right
2. Once all dots are lit, they dim from right to left
3. The cycle repeats continuously
4. Dot color matches your selected preference

## Smart Layout

When you toggle elements on/off, the app automatically:
- Resizes fonts to maximize readability
- Centers all content horizontally
- Ensures text never exceeds the display width
- Prioritizes the countdown time with larger fonts when space allows

## Installation

### For Personal Use

1. Clone this repository or download `countdowntimer.star`
2. Use the Tidbyt mobile app:
   - Open the app and select your device
   - Tap the "+" button
   - Choose "Upload" or "Developer"
   - Select the `countdowntimer.star` file
   - Configure your countdown settings

### For Community Submission

To share this app with the Tidbyt community:

1. Fork the [Tidbyt Community repository](https://github.com/tidbyt/community)
2. Add this app to the `apps/` directory
3. Include all necessary files:
   - `countdowntimer.star` - The main app code
   - `countdowntimer.webp` - A preview image
   - This README.md
4. Submit a pull request

## Configuration Examples

### Vacation Countdown
- Title: "Hawaii Trip"
- Dot Granularity: Days
- Colors: Blue title, Yellow time, Cyan dots

### Project Deadline
- Title: "Launch Day"
- Show Date: Off (for cleaner look)
- Dot Granularity: Hours
- Colors: Red theme for urgency

### Minimal Clock
- Show Title: Off
- Show Dots: Off
- Show Date: Off
- Result: Large countdown display only

## Development

Built with Pixlet using the Starlark language. Key features implemented:
- Responsive layout system
- Color-aware dimming for animations
- Automatic font sizing based on content
- Efficient frame generation for smooth animations

## Credits

Created with ❤️ for the Tidbyt community. Feel free to fork, modify, and share!

## License

MIT License - See LICENSE file for details