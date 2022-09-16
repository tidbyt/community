## Zoom Call Status

A Tidbyt app to display a user's current Zoom call status.

### Setup instructions

1. Create a new JWT Zoom app here: https://marketplace.zoom.us/develop/create?source=devdocs
2. Paste the JWT token into the token field in the application.
3. Set the email of the user who's status you wish to monitor.
4. Done.

### How it works

Every render one of two things happens, either we fetch the current status of the provided user from the API, or from the cache.  If the configuration is not correctly set, a message will be displayed detailing what is missing or what needs to be changed.  We can check for the presense of one of three status: In meeting, Presenting or Do Not Disturb, once detected, the app will display "On Air", otherwise it will display "Off Air".

### Examples

![On Air Example](./on_air.png)

![Off Air Example](./off_air.png)