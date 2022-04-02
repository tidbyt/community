// Package nhlscores provides details for the NHL Scores applet.
package nhlscores

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed nhl_scores.star
var source []byte

// New creates a new instance of the NHL Scores applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "nhl-scores",
		Name:        "NHL Scores",
		Author:      "cmarkham20",
		Summary:     "Displays NHL scores",
		Desc:        "Displays live and upcoming NHL scores from a data feed.",
		FileName:    "nhl_scores.star",
		PackageName: "nhlscores",
		Source:  source,
	}
}
