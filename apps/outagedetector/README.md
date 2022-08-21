# Outage Detector Applet for Tidbyt

This app makes up to 5 requests to a URL every 5 minutes and displays whether the URL responded successfully or not for up to the last hour.

- Each column on the plot graph represents a 5min block in the last hour.
- A full column on the plot indicates no failures were seen in that 5min block.
- The emoji on the right indicates whether the most recent call was a success or failure.
- The time below the emoji indicates how long the current success or failure has been seen.

![Outage Detector Applet Example](./outage_detector.png)