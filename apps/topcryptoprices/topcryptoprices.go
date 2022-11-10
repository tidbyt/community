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
		Summary:     "Top Crypto Prices",
		Desc:        "This app shows price info for the top cryptocurrencies. Prices are provided once per minute through the free Coingecko API.",
		FileName:    "top_crypto_prices.star",
		PackageName: "topcryptoprices",
		Source:  source,
	}
}
