# Progress Clock

**Author:** [Jeffery Bennett](https://meandmybadself.com)

See the time displayed & how much of the day has passed, as represented by a graph.

## Development

### In-browser development
`pixlet serve progressclock.star`

### Push graphic to device

`pixlet render progressclock.star && pixlet push "$TIDBYT_DEVICE_ID" progressclock.webp`

## Publishing

### Preflight linting

```
pixlet format progressclock.star && 
pixlet lint --fix progressclock.star &&
pixlet check -r .
```

### CLA

In the Pull Request, comment `I have read the CLA Document and I hereby sign the CLA`.

## Changelog

* 1.1 - Fixes support for custom timezones.
