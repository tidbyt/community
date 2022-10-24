// Package nflstandings provides details for the NFL Standings applet.
package nflstandings

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed nfl_standings.star
var source []byte

// New creates a new instance of the NFL Standings applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "nfl-standings",
		Name:        "NFL Standings",
		Author:      "LunchBox8484",
		Summary:     "NFL football standings",
		Desc:        "View NFL standings by division.",
		FileName:    "nfl_standings.star",
		PackageName: "nflstandings",
		Source:  source,
	}
}
