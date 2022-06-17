# Crypto Tracker for Tidbyt

Displays one of 5 24-hour cryptocurrency price charts in USD on your Tidbyt. Includes Bitcoin, Ethereum, Binance Coin, Cardano and Solana. Clockwise from symbol is 24-hour price change, 24-hour percentage, and current price. Below this is a 24-hour price graph. Data is provided by [AlphaVantage](https://www.alphavantage.co/documentation/#crypto-intraday) and updated every 15 minutes. No API key required currently.

![Crypto Tracker for Tidbyt](screenshot.png)

## Feature Ideas

- Allow users to specify their own API key and display one of the 575 cryptos that Alphavantage contains in their API. A full crypto choice is not possible now because all 5 choices are cached 96 times per day and the limits of the API are 500 calls/day. My initial concern with allowing the user to specify their own API key is error handling. Could also create multiple API keys and assign groups of cryptos to each key which would allow for more than 5 coin choices.
- Find API for commodity tracking and add support.
