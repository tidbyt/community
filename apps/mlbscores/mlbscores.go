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
		Author:      "LunchBox8484",
		Summary:     "MLB baseball scores",
		Desc:        "For slower scrolling of scores, add the app to your Tidbyt multiple times. Then, within each app instance, set 'Total Instances of App' to the amount of times you have it installed, and set 'App Instance Number' unique to each app instance.",
		FileName:    "mlb_scores.star",
		PackageName: "mlbscores",
		Source:  source,
	}
}
