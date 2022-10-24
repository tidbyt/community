// Package cryptotracker provides details for the Crypto Tracker applet.
package cryptotracker

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed crypto_tracker.star
var source []byte

// New creates a new instance of the Crypto Tracker applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "crypto-tracker",
		Name:        "Crypto Tracker",
		Author:      "Ethan Fuerst (@ethanfuerst)",
		Summary:     "Tracks crypto price",
		Desc:        "Display crypto prices in USD over the last 24 hours.",
		FileName:    "crypto_tracker.star",
		PackageName: "cryptotracker",
		Source:      source,
	}
}
