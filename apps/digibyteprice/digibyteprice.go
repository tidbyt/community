// Package digibyteprice provides details for the DigiByte Price applet.
package digibyteprice

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed digibyte_price.star
var source []byte

// New creates a new instance of the DigiByte Price applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "digibyte-price",
		Name:        "DigiByte Price",
		Author:      "Olly Stedall @saltedlolly",
		Summary:     "Display DigiByte Price",
		Desc:        "Displays the current DigiByte price in one or two fiat currencies and/or in Satoshis. Data provided by CoinGecko. Updated every 10 minutes. If you would like an additional currency supported, pease let me know in the Tidbyt community Discord.",
		FileName:    "digibyte_price.star",
		PackageName: "digibyteprice",
		Source:  source,
	}
}
