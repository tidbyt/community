// Package nhlstandings provides details for the NHL Standings applet.
package nhlstandings

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed nhl_standings.star
var source []byte

// New creates a new instance of the NHL Standings applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "nhl-standings",
		Name:        "NHL Standings",
		Author:      "LunchBox8484",
		Summary:     "NHL hockey standings",
		Desc:        "View NHL standings by division.",
		FileName:    "nhl_standings.star",
		PackageName: "nhlstandings",
		Source:  source,
	}
}
