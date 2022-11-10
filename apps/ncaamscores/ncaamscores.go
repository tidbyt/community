// Package ncaamscores provides details for the NCAAM Scores applet.
package ncaamscores

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed ncaam_scores.star
var source []byte

// New creates a new instance of the NCAAM Scores applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "ncaam-scores",
		Name:        "NCAA Basketball",
		Author:      "LunchBox8484",
		Summary:     "NCAA Mens Basketball Scores",
		Desc:        "For slower scrolling of scores, add the app to your Tidbyt multiple times. Then, within each app instance, set 'Total Instances of App' to the amount of times you have it installed, and set 'App Instance Number' unique to each app instance.",
		FileName:    "ncaam_scores.star",
		PackageName: "ncaamscores",
		Source:      source,
	}
}
