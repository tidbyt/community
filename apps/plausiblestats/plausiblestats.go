// Package plausiblestats provides details for the Plausible Stats applet.
package plausiblestats

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed plausible_stats.star
var source []byte

// New creates a new instance of the Plausible Stats applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "plausible-stats",
		Name:        "Plausible Stats",
		Author:      "brettohland",
		Summary:     "Display your website's Plausible stats",
		Desc:        "Works with your Plausible.io account to display your stats",
		FileName:    "plausible_stats.star",
		PackageName: "plausiblestats",
		Source:  source,
	}
}
