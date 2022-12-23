// Package mlsscores provides details for the MLS Scores applet.
package mlsscores

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed mls_scores.star
var source []byte

// New creates a new instance of the MLS Scores applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "mls-scores",
		Name:        "MLS Scores",
		Author:      "LunchBox8484",
		Summary:     "MLS soccer scores",
		Desc:        "For slower scrolling of scores, add the app to your Tidbyt multiple times. Then, within each app instance, set 'Total Instances of App' to the amount of times you have it installed, and set 'App Instance Number' unique to each app instance.",
		FileName:    "mls_scores.star",
		PackageName: "mlsscores",
		Source:  source,
	}
}
