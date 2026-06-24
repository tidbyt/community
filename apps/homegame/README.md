# HomeGame

A Tidbyt Gen2 applet.

## Setup

1. Install [Pixlet](https://github.com/tidbyt/pixlet)
2. Ensure pixlet is in your PATH

## Local Development

Run the app locally with live preview:

```bash
pixlet serve tidbyt/homegame.star --port 81
```

View at: http://localhost:81

## Deployment

### Render the app
```bash
pixlet render tidbyt/homegame.star
```

### Push to device
```bash
pixlet push <device_id> tidbyt/homegame.webp
```

## Configuration

See [tidbyt/README.md](tidbyt/README.md) for app-specific details.
