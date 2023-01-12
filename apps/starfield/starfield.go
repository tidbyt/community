// Package starfield provides details for the Starfield applet.
package starfield

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed starfield.star
var source []byte

// New creates a new instance of the Starfield applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "starfield",
		Name:        "Starfield",
		Author:      "gabe565",
		Summary:     "Fly through a starfield",
		Desc:        "This app simulates flying through a starfield.",
		FileName:    "starfield.star",
		PackageName: "starfield",
		Source:      source,
	}
}
