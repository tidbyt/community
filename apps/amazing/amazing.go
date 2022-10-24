// Package amazing provides details for the Amazing applet.
package amazing

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed amazing.star
var source []byte

// New creates a new instance of the Amazing applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "amazing",
		Name:        "Amazing",
		Author:      "dinosaursrarr",
		Summary:     "Draws lovely mazes",
		Desc:        "Draws mazes on the screen and animates progress as it goes.",
		FileName:    "amazing.star",
		PackageName: "amazing",
		Source:  source,
	}
}
