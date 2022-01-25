// Package clockbyhenry provides details for the Clock By Henry applet.
package clockbyhenry

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed clock_by_henry.star
var source []byte

// New creates a new instance of the Clock By Henry applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "clock-by-henry",
		Name:        "Clock By Henry",
		Author:      "Henry So, Jr.",
		Summary:     "Large Digit Time With Date",
		Desc:        "Show the time with numbers you can see from across the room! Bonus date included.",
		FileName:    "clock_by_henry.star",
		PackageName: "clockbyhenry",
		Source:  source,
	}
}
