// Package currencyconverter provides details for the CurrencyConverter applet.
package currencyconverter

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed currencyconverter.star
var source []byte

// New creates a new instance of the CurrencyConverter applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "currencyconverter",
		Name:        "CurrencyConverter",
		Author:      "Robert Ison",
		Summary:     "Displays Currency Exchange",
		Desc:        "Displays current currency exchange rates.",
		FileName:    "currencyconverter.star",
		PackageName: "currencyconverter",
		Source:  source,
	}
}
