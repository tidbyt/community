# Apple TV "Now Playing" for Tidbyt

Displays Apple TV's currently playing music, tv, video information on your Tidbyt.
Apple TV does not have Cloud APIs, so you will need to run a server locally to provide playing content information to Tidbyt. I wrote [tjmehta/apple-tv-now-playing-server](https://github.com/tjmehta/apple-tv-now-playing-server) on top of pyatv (thank you!) that will allow you to pair with your apple tv and read the "now playing" information and thumbnail. It has a Dockerfile so you can easily deploy it to any server running docker on your home network.

![Apple TV "Now Playing" for Tidbyt Screenshot](screenshot.gif)
