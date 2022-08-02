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
		Author:      "LunchBox8484",
		Summary:     "NBA basketball scores",
		Desc:        "For slower scrolling of scores, add the app to your Tidbyt multiple times. Then, within each app instance, set 'Total Instances of App' to the amount of times you have it installed, and set 'App Instance Number' unique to each app instance.",
		FileName:    "nba_scores.star",
		PackageName: "nbascores",
		Source:  source,
	}
}
