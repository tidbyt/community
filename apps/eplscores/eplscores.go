// Package eplscores provides details for the EPLScores applet.
package eplscores

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed eplscores.star
var source []byte

// New creates a new instance of the EPLScores applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "eplscores",
		Name:        "EPLScores",
		Author:      "mabroadfo1027",
		Summary:     "Displays EPL scores",
		Desc:        "Displays live and upcoming EPL scores from a data feed.",
		FileName:    "eplscores.star",
		PackageName: "eplscores",
		Source:  source,
	}
}
