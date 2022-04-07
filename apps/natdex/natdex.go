// Package pokedex provides details for the Pokedex applet.
package natdex

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed pokedex.star
var source []byte

// New creates a new instance of the Pokedex applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "natdex",
		Name:        "National Pokedex",
		Author:      "Lauren Kopac",
		Summary:     "Display a random Pokemon from Gen I - VII",
		Desc:        "Display a random Pokemon from your region of choice",
		FileName:    "natdex.star",
		PackageName: "natdex",
		Source:  source,
	}
}
