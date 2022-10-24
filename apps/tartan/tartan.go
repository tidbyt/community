// Package tartan provides details for the Tartan applet.
package tartan

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed tartan.star
var source []byte

// New creates a new instance of the Tartan applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "tartan",
		Name:        "Tartan",
		Author:      "dinosaursrarr",
		Summary:     "Weaves tartans to look at",
		Desc:        "Renders a tartan based on thread count instructions and displays it on screen.",
		FileName:    "tartan.star",
		PackageName: "tartan",
		Source:  source,
	}
}
