# Roomba

Show status of Roomba. Requires a server (raspbi on local network preferrably) running `index.js` to communicate to the Roomba through MQTT protocol. 

![](./roomba1.gif)
![](./roomba2.gif)
![](./roomba3.gif)

This project may be possible without the use of this server - by calling http requests to the Roomba API straight from the pixlet `roomba.star`. However, this may only be possible on older versions of roomba firmware. As I understand it, the newer firmware's use mqtt protocol to transfer data, so for that you need a server in the middle to interface and convert the flow to http. For more information, see https://github.com/koalazak/dorita980

## Config

`serverIP` IP of the server which has `index.js` running.

`serverPORT` (optional) Port of the server. Defaults to 6565.

`roombaIP` (optional) IP of the Roomba. If left blank, the server will automatically search for the IP, in testing, this adds `500ms` to the request time.

## Server Set up
1. NodeJS is installed
2. Copy contents of `/server`
3. Run `npm i`
4. Run `npm install -g dorita980`
5. Run `get-roomba-password-cloud <iRobot Username> <iRobot Password> [Optional API-Key]`. This takes your iRobot username and password. The same you would use to sign into the app or website.
6. Take the resulting `username/blid` and `password` values and paste into `index.js`
7. Run `npm start` to start the server