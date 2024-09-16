# Daily Countdown

**Author:** [Jeffery Bennett](https://meandmybadself.com)

A countdown designed to display a daily countdown to a specific time.


## Development

### In-browser development
`pixlet serve dailycountdown.star`

### Push graphic to device

`pixlet render dailycountdown.star && pixlet push "$TIDBYT_DEVICE_ID" dailycountdown.webp`

## Publishing

### Preflight linting

```
pixlet format dailycountdown.star && 
pixlet lint --fix dailycountdown.star &&
pixlet check -r .
```

### CLA

In the Pull Request, comment `I have read the CLA Document and I hereby sign the CLA`.

## Changelog

* 1.0 - Intial release.
