// Package stockticker provides details for the Stock Ticker applet.
package stockticker

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed stock_ticker.star
var source []byte

// New creates a new instance of the Stock Ticker applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "stock-ticker",
		Name:        "Stock Ticker",
		Author:      "Matt Holloway",
		Summary:     "3 stocks scrolling",
		Desc:        "This is a simple stock ticker app, that will display a stock ticker for 3 stock symbols.  If you want more, spin up a second copy of the app to have more stocks tick. Requires a free API key from alphavantage.co.",
		FileName:    "stock_ticker.star",
		PackageName: "stockticker",
		Source:  source,
	}
}
