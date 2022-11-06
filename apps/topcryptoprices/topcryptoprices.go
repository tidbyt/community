// Package topcryptoprices provides details for the Top Crypto Prices applet.
package topcryptoprices

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed top_crypto_prices.star
var source []byte

// New creates a new instance of the Top Crypto Prices applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "top-crypto-prices",
		Name:        "Top Crypto Prices",
		Author:      "playak",
		Summary:     "Top Crypto USD Prices",
		Desc:        "This app show price info for the top 10 cryptocurrencies in USD. Prices are priveded once per minute through the Coingecko API.",
		FileName:    "top_crypto_prices.star",
		PackageName: "topcryptoprices",
		Source:  source,
	}
}
