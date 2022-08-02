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
		Author:      "LunchBox8484",
		Summary:     "NFL football scores",
		Desc:        "For slower scrolling of scores, add the app to your Tidbyt multiple times. Then, within each app instance, set 'Total Instances of App' to the amount of times you have it installed, and set 'App Instance Number' unique to each app instance.",
		FileName:    "nfl_scores.star",
		PackageName: "nflscores",
		Source:  source,
	}
}
