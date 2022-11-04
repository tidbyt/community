// Package sportsscores provides details for the Sports Scores applet.
package sportsscores

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed sports_scores.star
var source []byte

// New creates a new instance of the Sports Scores applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "sports-scores",
		Name:        "Sports Scores",
		Author:      "rs7q5",
		Summary:     "Get daily sports scores",
		Desc:        "Get daily scores or live updates of sports. Scores for the previous day are shown until 11am ET.",
		FileName:    "sports_scores.star",
		PackageName: "sportsscores",
		Source:  source,
	}
}
