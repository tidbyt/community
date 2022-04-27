// Package nbascores provides details for the NBA Scores applet.
package nbascores

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed nba_scores.star
var source []byte

// New creates a new instance of the NBA Scores applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "nba-scores",
		Name:        "NBA Scores",
		Author:      "cmarkham20",
		Summary:     "Displays NBA scores",
		Desc:        "Displays live and upcoming NBA scores from a data feed.",
		FileName:    "nba_scores.star",
		PackageName: "nbascores",
		Source:  source,
	}
}
