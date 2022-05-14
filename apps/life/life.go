// Package life provides details for the Life applet.
package life

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed life.star
var source []byte

// New creates a new instance of the Life applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "life",
		Name:        "Life",
		Author:      "dinosaursrarr",
		Summary:     "Conways Game of Life",
		Desc:        "Runs a famous cellular automaton and animates the state on screen.",
		FileName:    "life.star",
		PackageName: "life",
		Source:  source,
	}
}
