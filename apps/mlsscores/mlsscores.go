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
		Author:      "cmarkham20",
		Summary:     "Displays MLS soccer scores",
		Desc:        "For slower scrolling of scores, add the app to your Tidbyt multiple times.",
		FileName:    "mls_scores.star",
		PackageName: "mlsscores",
		Source:  source,
	}
}
