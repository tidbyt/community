
# Awair

An app to render data from an [Awair](https://www.getawair.com/) device.

Unconfigured:

<img src="./screenshot-unconfigured.webp" width="320" height="160">

Configured:

<img src="./screenshot-configured.webp" width="320" height="160">

Selecting bar chart display option:

<img src="./screenshot-bar-chart.webp" width="320" height="160">

showing temperature, humidity, CO2, VOCs, PM2.5 in the same order as the Awair device and app.


## Reference

### Awair developer docs

https://docs.developer.getawair.com/

### Awair Cloud API quotas

Note that Awair's published quota is 300 calls per day, which works out to about one call every 4.8 minutes. This is obviously not as good as true real-time data, but exceeding this limit will result in an error message:

<img src="./screenshot-quota-exceeded.webp" width="320" height="160">

To ensure this quota is not exceeded during a 24-hour period, data is cached for 5 minutes (meaning it may be up to five minutes out of date).


## API choices and authentications

There are a few ways that this Tidbyt app can retrieve data from your Awair device.

### Local API

https://support.getawair.com/hc/en-us/search?query=Awair+Local+API+Feature

> Once activated, your Awair device has the ability to host data on a server that lives on the
> device. It is like a miniature website with webpages that you can view in your browser (or use
> software to programmatically retrieve data), but only while you are connected to the same Local
> Area Network (LAN). The LAN exists behind your router’s firewall, which protects your network from
> the Wide Area Network (WAN), so this server is secure behind your firewall unless you specifically
> make it accessible to the internet. The Local API is a miniature website, which serves data from
> the Awair sensors.

Read the docs linked above to learn how to enable this feature on your Awair device.

PLEASE NOTE: that you must make your device available via an internet-routable IP address and port, so that the Tidbyt servers can connect to it.

### Cloud API using a Bearer Token

Visit the Awair "Developer console" where you can generate an access (bearer) token:

https://developer.getawair.com/console/access-token

To verify that your bearer token works, try:

``` sh
curl https://developer-apis.awair.is/v1/users/self -H "authorization: Bearer ${token}"
```

To configure this Tidbyt app, you'll also need to know the `deviceId` and `deviceType` for your Awair device.
To retrieve a list of your devices, try:

``` sh
curl https://developer-apis.awair.is/v1/users/self/devices -H "authorization: Bearer ${token}"
```

The `deviceId` is an integer, and the `deviceType` is a string, likely either "awair-element" or "awair-r2".

### Cloud API using OAuth2 user authentication

Not yet supported by this app.

## Potential future work

- OAuth2 support
- use a mix of `LATEST` and `RAW` cloud API calls to get around the daily quota
