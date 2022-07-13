// Package petpikachu provides details for the Pet Pikachu applet.
package petpikachu

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed petpikachu.star
var source []byte

// New creates a new instance of the Pet Pikachu applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "petpikachu",
		Name:        "Pet Pikachu",
		Author:      "Kyle Stark",
		Summary:     "Virtual pet Pikachu",
		Desc:        "Based on the Pokémon Pikachu virtual pet from the 90s",
		FileName:    "petpikachu.star",
		PackageName: "petpikachu",
		Source:      source,
	}
}
