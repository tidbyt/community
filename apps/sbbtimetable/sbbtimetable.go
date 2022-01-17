// Package sbbtimetable provides details for the SBB Timetable applet.
package sbbtimetable

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed sbb_timetable.star
var source []byte

// New creates a new instance of the SBB Timetable applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "sbb-timetable",
		Name:        "SBB Timetable",
		Author:      "LukiLeu",
		Summary:     "SBB Timetable",
		Desc:        "Shows a timetable for a station in the Swiss Public Transport network.",
		FileName:    "sbb_timetable.star",
		PackageName: "sbbtimetable",
		Source:  source,
	}
}
