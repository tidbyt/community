// Package nhlnextgame provides details for the NHL Next Game applet.
package nhlnextgame

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed nhl_next_game.star
var source []byte

// New creates a new instance of the NHL Next Game applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "nhl-next-game",
		Name:        "NHL Next Game",
		Author:      "AKKanMan",
		Summary:     "Gets Next Game Info",
		Desc:        "Gets info on preferred NHL teams next game.",
		FileName:    "nhl_next_game.star",
		PackageName: "nhlnextgame",
		Source:  source,
	}
}
