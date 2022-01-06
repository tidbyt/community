# Publishing Apps
So pumped you're here and want to publish an app! If you haven't done so already, check out our [contribiting guide](../CONTRIBUTING.md) and our guide on [app philosophy](app_philoshpy.md) to get a better sense of what you're getting yourself into.

## Prerequisites
Make sure you have [go1.16](https://go.dev/) or later and `make` installed on your system.

## Quickstart
Run the following to generate everything you need!
```
make app
```

> Note: the codegen tool is a bit picky. This is because these strings show up in the Tidbyt mobile app and we want to ensure the UX works as expected.

Once created, edit `apps/{{appaname}}/{{app_name}}.star` with your source code.

## Example
Generate your app:
```
$ make app
Name (what do you want to call your app?): Tides
Summary (what's the short and sweet of what this app does?): Tide charts
Description (what's the long form of what this app does?): Daily tide charts for your location.
Author (your name or your Github handle): Mark Spicer
```

Run your app:
```
pixlet serve --watch apps/tides/tides.star
```

## Fields
In this example, the fields map as follows:
- **Name**: Fuzzy Clock
- **Summary**: Human readable time
- **Description**: Display the time in a groovy, human-readable way.
- **Author**: Max Timkovich

![example](../assets/example.png)

![details](../assets/example_details.png)


## Making a PR
When you go to make a PR, give us a little background on what your app does. In addition, include a render from the following command so we can ooh-ahh 😍:
```
pixlet render apps/{{appname}}/{{app_name}}.star --gif --magnify 10
```



