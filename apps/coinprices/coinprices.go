// Package coinprices provides details for the Coin Prices applet.
package coinprices

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed coin_prices.star
var source []byte

// New creates a new instance of the Coin Prices applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "coin-prices",
		Name:        "Coin Prices",
		Author:      "alan-oliv",
		Summary:     "Show coin price",
		Desc:        "Show Current exchange rate for multiple coins.",
		FileName:    "coin_prices.star",
		PackageName: "coinprices",
		Source:  source,
	}
}
