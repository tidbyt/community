// Package bgghotness provides details for the BGG Hotness applet.
package bgghotness

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed bgg_hotness.star
var source []byte

// New creates a new instance of the BGG Hotness applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "bgg-hotness",
		Name:        "BGG Hotness",
		Author:      "Henry So, Jr.",
		Summary:     "BoardGameGeek Hotness",
		Desc:        "Shows the top items from BoardGameGeek's Board Game Hotness list.",
		FileName:    "bgg_hotness.star",
		PackageName: "bgghotness",
		Source:  source,
	}
}
