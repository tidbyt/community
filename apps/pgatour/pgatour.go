// Package pgatour provides details for the PGA Tour applet.
package pgatour

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed pga_tour.star
var source []byte

// New creates a new instance of the PGA Tour applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "pga-tour",
		Name:        "PGA Tour",
		Author:      "M0ntyP",
		Summary:     "Shows PGA Leaderboard",
		Desc:        "This app displays the leaderboard for the current PGA Tour event, taken from ESPN data feed. The leaderboard will show the first 24 players. Players currently on course are shown in different shades of yellow - going from dark yellow for those players just starting to white for those who have completed their rounds. Players who have not started are shown in green.",
		FileName:    "pga_tour.star",
		PackageName: "pgatour",
		Source:  source,
	}
}
