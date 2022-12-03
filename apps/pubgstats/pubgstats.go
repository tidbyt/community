// Package pubgstats provides details for the PUBG Stats applet.
package pubgstats

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed pubg_stats.star
var source []byte

// New creates a new instance of the PUBG Stats applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "pubg-stats",
		Name:        "PUBG Stats",
		Author:      "joes-io",
		Summary:     "Shows PUBG Player Stats",
		Desc:        "Displays individual player's gaming stats from PlayerUnknown's Battlegrounds.",
		FileName:    "pubg_stats.star",
		PackageName: "pubgstats",
		Source:  source,
	}
}
