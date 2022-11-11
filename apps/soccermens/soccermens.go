// Package nascarnextrace provides details for the NASCAR next race applet.
package soccermens

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed soccermens.star
var source []byte

// New creates instance of applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "soccermens",
		Name:        "Mens Soccer",
		Author:      "jvivona",
		Summary:     "Mens Soccer scores",
		Desc:        "Shows upcoming games, current score, date and time of game for selected league / tournament.",
		FileName:    "soccermens.star",
		PackageName: "soccermens",
		Source:      source,
	}
}
