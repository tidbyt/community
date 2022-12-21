// Package goldpriceticker provides details for the GoldpriceTicker applet.
package goldpriceticker

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed goldpriceticker.star
var source []byte

// New creates a new instance of the GoldpriceTicker applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "goldpriceticker",
		Name:        "GoldpriceTicker",
		Author:      "Aaron Brace",
		Summary:     "Precious Metal Quotes",
		Desc:        "Close to realtime precious metal prices and a graph comparing the price to the 5PM closing price from the day before.",
		FileName:    "goldpriceticker.star",
		PackageName: "goldpriceticker",
		Source:  source,
	}
}
