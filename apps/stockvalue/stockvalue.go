// Package stockvalue provides details for the Stock Value applet.
package stockvalue

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed stock_value.star
var source []byte

// New creates a new instance of the Stock Value applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "stock-value",
		Name:        "Stock Value",
		Author:      "gshipley",
		Summary:     "Portfolio value",
		Desc:        "This app will allow you track the value of your portfolio for a single stock. Get your API key for Alpha Vantage at https://www.alphavantage.co.",
		FileName:    "stock_value.star",
		PackageName: "stockvalue",
		Source:  source,
	}
}
