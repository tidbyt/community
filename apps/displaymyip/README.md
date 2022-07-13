# Display My IP

A really simple applet that will query the IPify API and display your current public IP. I will admit this was mostly to learn how to write apps for the Tidbyt, and hopefully once I get this running on mine, I can ditch the "whatsmyip" bash alias.

It could definitely use some polishing, but it seems like a good starter.

![Display my IP](display_my_ip.gif)

## External APIs used

Just https://api.ipify.org, which is an extremely simple API.

Example query:

```bash
$ curl 'https://api.ipify.org?format=json'
{"ip":"65.25.96.157"}%
````

## Options

`cache`: if true, the API call will be cached in memory for 5 minutes.
