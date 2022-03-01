// Package pacman provides details for the Pac-Man applet.
package pacman

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed pac_man.star
var source []byte

// New creates a new instance of the Pac-Man applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "pac-man",
		Name:        "Pac-Man",
		Author:      "Steve Otteson",
		Summary:     "Animated Pac-Man & friends",
		Desc:        "Pac-Man, Ms. Pac-Man, and the ghosts chase each other.",
		FileName:    "pac_man.star",
		PackageName: "pacman",
		Source:  source,
	}
}
