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
		Author:      "LunchBox8484",
		Summary:     "NHL hockey scores",
		Desc:        "For slower scrolling of scores, add the app to your Tidbyt multiple times. Then, within each app instance, set 'Total Instances of App' to the amount of times you have it installed, and set 'App Instance Number' unique to each app instance.",
		FileName:    "nhl_scores.star",
		PackageName: "nhlscores",
		Source:  source,
	}
}
