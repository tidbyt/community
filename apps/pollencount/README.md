# Pollen Count

Shows the current allergen count for your general area. Lists the current count 1-5 and which types of pollen are in the air.

![Sample Pollen Count](pollencount-preview.png)

## APIs Used

This uses the Tomorrow.io API and pulls data every 12 hours. The rate limit is 500 calls per day. This means that this app will begin to show rate limit issues when more than 250 people are using it, if they're in different metro areas. All latitudes are rounded to the nearest 0.5 to try to minimize that problem as much as possible.