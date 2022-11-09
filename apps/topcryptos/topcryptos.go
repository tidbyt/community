// Package topcryptos provides details for the Top Cryptos applet.
package topcryptos

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed top_cryptos.star
var source []byte

// New creates a new instance of the Top Cryptos applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "top-cryptos",
		Name:        "Top Cryptos",
		Author:      "playak",
		Summary:     "Top Cryptocurrency Prices",
		Desc:        "The latest prices of the most important cryptocurrencies.",
		FileName:    "top_cryptos.star",
		PackageName: "topcryptos",
		Source:  source,
	}
}
