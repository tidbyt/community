// Package nflscores provides details for the NFL Scores applet.
package nflscores

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed nfl_scores.star
var source []byte

// New creates a new instance of the NFL Scores applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "nfl-scores",
		Name:        "NFL Scores",
		Author:      "cmarkham20",
		Summary:     "Displays NFL scores",
		Desc:        "Displays live and upcoming NFL scores from a data feed.",
		FileName:    "nfl_scores.star",
		PackageName: "nflscores",
		Source:  source,
	}
}
