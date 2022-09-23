// Package hexdailystats provides details for the HEX Daily Stats applet.
package hexdailystats

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed hex_daily_stats.star
var source []byte

// New creates a new instance of the HEX Daily Stats applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "hex-daily-stats",
		Name:        "HEX Daily Stats",
		Author:      "kmphua",
		Summary:     "HEX Daily Stats",
		Desc:        "Displays HEX price, Payout per T-Share and T-Share rate",
		FileName:    "hex_daily_stats.star",
		PackageName: "hexdailystats",
		Source:  source,
	}
}
