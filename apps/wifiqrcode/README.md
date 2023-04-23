# WiFi QR Code Generator App for Tidbyt
A WiFi QR code app for the Tidbyt.

This app creates a scannable WiFi QR Code. It is not compatible with Enterprise networks. Also, there are display limitations with the Tidbyt and it's QR code library, so not all networks will be able to be encoded.

![WiFi QR Code App for Tidbyt](wifi_qr_code.gif)

There are three things the app will ask you to provide:

1. Your WiFi SSID/Network name.
2. Your password.
3. The encryption method. Either WEP or WPA/WPA2/WPA3 (All WPA methods get encoded the same way).

If the QR code displays, then by simply scanning the QR code, your phone will join the network!

This app would be amazing to display in your home, bar, restaurant, and/or shop!

## Limitations
The current QR Code library used by the Tidbyt only allows for a maximum of 440 bits or 55 bytes to be encoded. Since the WiFi QR syntax uses 18 bytes, including the encryption method, that leaves 37 characters that can be encoded into a useable QR code, shared between the SSID and the WiFi password. This app has a method that checks for this and displays an error if your network cannot be encoded. 

If you get an error and you still want to encode your WiFi network, then you can either do the following:
1. Shorten your SSID. 
2. Change your WiFi password. 

These characters in the WiFi password are not compatible: `\ ; , " and :`

Enterprise networks are not compatible. This is because:
1. There is no widely accepted standard in Android/iOS for the field names used to encode an enterprise network. 
2. The bits required to encode an enterprise network will pass the 55 byte limit.

## Credits
I was inspired by [@evgeni's](https://github.com/evgeni) (qifi project)[https://github.com/evgeni/qifi]. His app is [here](https://qifi.org/).
