# Twitter Trends Applet for Tidbyt
# Author: Joseph Esposito

Displays the top number of Trending Hashtags on Twitter. The limit is set in a schema which maxes at 50.

Colors of the trend's text determine how many tweets it has. 
White: No Volume Data, 
Green: Less then 25K, 
Blue: 25K - 100K, 
Orange: 100K - 250K, 
Purple: 250K - 500K, 
Red: More than 500K.

Data is retrived from Twitters API v1.1. To use this, an elevated developers account is needed, which was free and takes 10 minutes. 
(if there is a better way of doing this please share)
They provide you with a key and a secret key which I used to authenticate with a POST request. 
Twitter returns the access_token from the POST and then that is used for the GET request.
It uses Twitters API v1.1 because that has a GET request for the top trends, I did not see a similar request in their v2

# Problems 
I have not been able to use the schema.star, so I am unable to verify that you can authenticate it using the schema.OAuth2.
Currently I have all the schema code commented out in order to test it.
My hope is that this is possible but without testing it, my implementation could vary slightly and needs to be adjusted to work with the schema.
I am not very well versed in APIs or authenticating them. I got the Tidbyt to start diving in!

# Notes
Currently it handles long text in a way that will just cut it off, this was done on purpose in order to keep the display consistant and without scrolling in 2 directions. 
This is something that can be adjusted if wanted.

#Future Features
An idea for an additional feature is to allow the user to choose colors for the volume range of a tweet.
