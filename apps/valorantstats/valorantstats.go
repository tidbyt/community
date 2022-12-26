// Package valorantstats provides details for the VALORANT Stats applet.
package valorantstats

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed valorant_stats.star
var source []byte

// New creates a new instance of the VALORANT Stats applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "valorant-stats",
		Name:        "VALORANT Stats",
		Author:      "ohdxnte",
		Summary:     "Live VALORANT Rank Stats",
		Desc:        "Pulls live VALORANT rank stats using henrikdev's Valorant API based on provided Riot ID.",
		FileName:    "valorant_stats.star",
		PackageName: "valorantstats",
		Source:  source,
	}
}
