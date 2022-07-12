# Hayward Omnilogic

This app reads the latest pool temperature from the Hayward Omnilogic Controller, and displays it on the Tidbyt.

![](hayward_omnilogic.png)


## Getting a Token

Hayward does not provide an Oauth2 flow, and Tidbyt does not support storing username/password credentials, so you must manually get a token to use in the app.

To obtain a token, execute the following command by replacing YOUR_USERNAME and YOUR_PASSWORD with your credentials to login to the app. 

```
curl -X "POST" "https://www.haywardomnilogic.com/MobileInterface/MobileInterface.ashx" \
     -H 'Content-Type: text/xml' \
     -d $'<Request> 
	<Name>Login</Name> 
	<Parameters> 
		<Parameter name="UserName" dataType="String">YOUR_USERNAME</Parameter> 
		<Parameter name="Password" dataType="String">YOUR_PASSWORD</Parameter> 
	</Parameters> 
</Request>'

```

The response will be XML and contain a parameter named `Token`. Grab the value from this field, and use in the app.

## Getting the MSP ID

To get the MSP ID for your Hayward system, follow these instructions:

1. Open the Hayward App
2. Go to the Menu tab
3. Select About
4. The MSP ID will be presented in the popup 