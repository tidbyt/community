// Package sportsrankings provides details for the Sports Rankings applet.
package sportsrankings

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed sports_rankings.star
var source []byte

// New creates a new instance of the Sports Rankings applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "sports-rankings",
		Name:        "Sports Rankings",
		Author:      "Derek Holevinsky",
		Summary:     "Shows rankings for sports",
		Desc:        "Shows the AP poll rankings for various sports. Currently supports college football and men's and women's college basketball.",
		FileName:    "sports_rankings.star",
		PackageName: "sportsrankings",
		Source:  source,
	}
}
