// Package bored provides details for the Bored applet.
package bored

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed bored.star
var source []byte

// New creates a new instance of the Bored applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "bored",
		Name:        "Bored",
		Author:      "Anders Heie",
		Summary:     "Things to do when bored",
		Desc:        "This app will suggest things you can do alone or with your friends if you are bored.",
		FileName:    "bored.star",
		PackageName: "bored",
		Source:  source,
	}
}
