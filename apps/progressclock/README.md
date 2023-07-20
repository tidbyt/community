# Progress Clock

**Author:** [Jeffery Bennett](https://meandmybadself.com)

See the time displayed & how much of the day has passed, as represented by a graph.

<img src='./git-image.webp' alt='Example image of application running' width='300px' />

## Development

### Push graphic to device

`pixlet render progressclock.star && pixlet push "$TIDBYT_DEVICE_ID" progressclock.webp`

## Publishing

* `pixlet format progressclock.star`
* `pixlet lint --fix progressclock.star`
* `pixlet check -r .`

In the Pull Request, comment `I have read the CLA Document and I hereby sign the CLA`.