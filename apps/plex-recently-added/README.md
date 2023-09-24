# Plex Recently Added

Shows recently added on plex server. Strongly recommend to run `index.js` as a proxy to communicate securely to the plex server. **It can be used without the use of running the proxy server `index.js`**, but you will need to **disable `Secure Connections: Required`, and use `Preferred` instead** (found in the network tab in your plex server settings). This is recommended against as it is a **security risk.**

![](./plex-recently-added.gif)

## Config

`serverIP` IP of the server which has `index.js` running, OR the IP of the plex server if "Secure Connections" is set to `Preferred` (do not recommend).

`serverPORT` Port of the server. Usually 32400.

`plexToken` Follow [this article](https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/) on how to find this value.

## Server/Proxy Set up
1. NodeJS is installed
2. Copy `package.json` and `index.js` to server.
3. Run `npm i`
4. Ensure hosts and ports are configured correctly.
6. Set up your own `API_KEY` and enter the same in the tidbyt app.
7. Run `npm start` to start the server