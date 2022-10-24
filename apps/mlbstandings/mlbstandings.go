// Package mlbstandings provides details for the MLB Standings applet.
package mlbstandings

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed mlb_standings.star
var source []byte

// New creates a new instance of the MLB Standings applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "mlb-standings",
		Name:        "MLB Standings",
		Author:      "LunchBox8484",
		Summary:     "MLB baseball standings",
		Desc:        "View MLB standings by division.",
		FileName:    "mlb_standings.star",
		PackageName: "mlbstandings",
		Source:  source,
	}
}
