// Package steam provides details for the Steam applet.
package steam

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed steam.star
var source []byte

// New creates a new instance of the Steam applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "steam",
		Name:        "Steam",
		Author:      "Jeremy Tavener",
		Summary:     "Steam Now Playing",
		Desc:        "Displays the game that the specified user is currently playing, or the most recent games if currently not in-game.",
		FileName:    "steam.star",
		PackageName: "steam",
		Source:  source,
	}
}
