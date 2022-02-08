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
		Desc:        "Displays current game or previous games. Use https://steamid.xyz/ to find your 17 digit Steam ID.",
		FileName:    "steam.star",
		PackageName: "steam",
		Source:      source,
	}
}
