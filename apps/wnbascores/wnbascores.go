// Package wnbascores provides details for the WNBA Scores applet.
package wnbascores

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed wnba_scores.star
var source []byte

// New creates a new instance of the WNBA Scores applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "wnba-scores",
		Name:        "WNBA Scores",
		Author:      "LunchBox8484",
		Summary:     "WNBA basketball scores",
		Desc:        "For slower scrolling of scores, add the app to your Tidbyt multiple times. Then, within each app instance, set 'Total Instances of App' to the amount of times you have it installed, and set 'App Instance Number' unique to each app instance.",
		FileName:    "wnba_scores.star",
		PackageName: "wnbascores",
		Source:  source,
	}
}
