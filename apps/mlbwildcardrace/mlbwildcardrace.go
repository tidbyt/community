// Package mlbwildcardrace provides details for the MLB WildCard Race applet.
package mlbwildcardrace

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed mlb_wildcard_race.star
var source []byte

// New creates a new instance of the MLB WildCard Race applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "mlb-wildcard-race",
		Name:        "MLB WildCard Race",
		Author:      "Jake Manske",
		Summary:     "Display wild card race",
		Desc:        "Displays the standings (in terms of games behind) for the MLB wild card in each league.",
		FileName:    "mlb_wildcard_race.star",
		PackageName: "mlbwildcardrace",
		Source:  source,
	}
}
