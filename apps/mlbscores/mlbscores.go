// Package mlbscores provides details for the MLB Scores applet.
package mlbscores

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed mlb_scores.star
var source []byte

// New creates a new instance of the MLB Scores applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "mlb-scores",
		Name:        "MLB Scores",
		Author:      "cmarkham20",
		Summary:     "Displays MLB scores",
		Desc:        "Displays live and upcoming MLB scores from a data feed.",
		FileName:    "mlb_scores.star",
		PackageName: "mlbscores",
		Source:  source,
	}
}
