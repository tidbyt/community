// Package coingeckoprice provides details for the CoinGecko Price applet.
package coingeckoprice

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed coingecko_price.star
var source []byte

// New creates a new instance of the CoinGecko Price applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "coingecko-price",
		Name:        "CoinGecko Price",
		Author:      "Allen Schober (@aschober)",
		Summary:     "Crypto price from CoinGecko",
		Desc:        "Displays the current price of any coin supported by CoinGecko against one or two other currencies. Crypto price data updated every 10 minutes. Data provided by CoinGecko.",
		FileName:    "coingecko_price.star",
		PackageName: "coingeckoprice",
		Source:  source,
	}
}
