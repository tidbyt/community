// Package blackout provides details for the Blackout applet.
package blackout

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed blackout.star
var source []byte

// New creates a new instance of the Blackout applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "blackout",
		Name:        "Blackout",
		Author:      "mabroadfo1027",
		Summary:     "Blackout tidbyt",
		Desc:        "Black out Tidbyt during evenings (or whenever).",
		FileName:    "blackout.star",
		PackageName: "blackout",
		Source:  source,
	}
}
