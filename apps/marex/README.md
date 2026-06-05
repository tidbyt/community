# Marex

Tidbyt/Pixlet applet that renders today's tide table for Brazilian beachs.

The first version defaults to the Cabedelo station (`pb01`) and calls:

```text
https://tabuamare.devtu.qzz.io/api/v2/tabua-mare/pb01/{month}/{day}
```

`{month}` is the current month in `MM` format and `{day}` is the current local day for the configured timezone.

## Development

Install Pixlet from the official repository:

```sh
brew install tidbyt/tidbyt/pixlet
```

Render the app locally:

```sh
pixlet render marex.star
```

Serve and auto-refresh while editing:

```sh
pixlet serve --watch marex.star
```

Run the community app checks before submitting:

```sh
pixlet check marex.star
```

## Configuration

The app exposes two optional configuration values:

- `harbor_id`: defaults to `pb01`.
- `timezone`: defaults to `America/Fortaleza`.

For local testing:

```sh
pixlet render marex.star harbor_id=pb01 timezone=America/Fortaleza
```
