// Package ncaafscores provides details for the NCAAF Scores applet.
package ncaafscores

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed ncaaf_scores.star
var source []byte

// New creates a new instance of the NCAAF Scores applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "ncaaf-scores",
		Name:        "NCAAF Scores",
		Author:      "LunchBox8484",
		Summary:     "NCAAF football scores",
		Desc:        "For slower scrolling of scores, add the app to your Tidbyt multiple times. Then, within each app instance, set 'Total Instances of App' to the amount of times you have it installed, and set 'App Instance Number' unique to each app instance.",
		FileName:    "ncaaf_scores.star",
		PackageName: "ncaafscores",
		Source:      source,
	}
}
