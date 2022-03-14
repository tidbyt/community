// Package coingeckocryptoprice provides details for the CoinGecko Crypto Price applet.
package coingeckocryptoprice

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed coingecko_crypto_price.star
var source []byte

// New creates a new instance of the CoinGecko Crypto Price applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "coingecko-crypto-price",
		Name:        "CoinGecko Crypto Price",
		Author:      "Allen Schober @allenschober",
		Summary:     "Display the price of a cryptocurrency against one or two other currencies.",
		Desc:        "Displays the current price of any coin supported by CoinGecko against one or two other currencies. Crypto price data updated every 10 minutes. Data provided by CoinGecko.",
		FileName:    "coingecko_crypto_price.star",
		PackageName: "coingeckocryptoprice",
		Source:  source,
	}
}
