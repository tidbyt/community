// Package whosthatpokemon provides details for the WhosThatPokemon? applet.
package whosthatpokemon

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed whosthatpokemon.star
var source []byte

// New creates a new instance of the WhosThatPokemon? applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "whosthatpokemon",
		Name:        "WhosThatPokemon?",
		Author:      "Nicole Brooks",
		Summary:     "Pokemon Quiz Game",
		Desc:        "Test your Pokemon Master knowledge with this rendition of \"Who's That Pokemon?\". Turn off classic mode to crank up the difficulty. Set your Tidbyt speed to ensure the animation takes up exactly half the time is has displayed.",
		FileName:    "whosthatpokemon.star",
		PackageName: "whosthatpokemon",
		Source:  source,
	}
}
