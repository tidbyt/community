// Package nbastandings provides details for the NBA Standings applet.
package nbastandings

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed nba_standings.star
var source []byte

// New creates a new instance of the NBA Standings applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "nba-standings",
		Name:        "NBA Standings",
		Author:      "LunchBox8484",
		Summary:     "NBA basketball standings",
		Desc:        "View NBA standings by division.",
		FileName:    "nba_standings.star",
		PackageName: "nbastandings",
		Source:  source,
	}
}
