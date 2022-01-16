// Package pokedex provides details for the Pokedex applet.
package pokedex

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed pokedex.star
var source []byte

// New creates a new instance of the Pokedex applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "pokedex",
		Name:        "Pokedex",
		Author:      "Mack Ward",
		Summary:     "Display a random Pokemon",
		Desc:        "Display a random Pokemon alongside its name, number, height, and weight.",
		FileName:    "pokedex.star",
		PackageName: "pokedex",
		Source:  source,
	}
}
