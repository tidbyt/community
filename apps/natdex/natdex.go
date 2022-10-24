// Package natdex provides details for the natdex applet.
package natdex

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed natdex.star
var source []byte

// New creates a new instance of the natdex applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "natdex",
		Name:        "National Pokedex",
		Author:      "Lauren Kopac",
		Summary:     "Display random Pokemon",
		Desc:        "Display a random Pokemon from your region of choice.",
		FileName:    "natdex.star",
		PackageName: "natdex",
		Source:      source,
	}
}
