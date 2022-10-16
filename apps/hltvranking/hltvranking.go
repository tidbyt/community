// Package hltvranking provides details for the DigiByte Price applet.
package hltvranking

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed hltvranking.star
var source []byte

// New creates a new instance of the HLTV Ranking applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "hltv-ranking",
		Name:        "HLTV Ranking",
		Author:      "Joe Cardali @jcardali",
		Summary:     "HLTV CS:GO World Ranking",
		Desc:        "Displays the top four teams in HLTV's Counter-Strike: Global Offensive World Ranking.",
		FileName:    "hltvranking.star",
		PackageName: "hltvranking",
		Source:  source,
	}
}