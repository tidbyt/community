// Package datetimeclock provides details for the Date Time Clock applet.
package datetimeclock

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed date_time_clock.star
var source []byte

// New creates a new instance of the Date Time Clock applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "date-time-clock",
		Name:        "Date Time Clock",
		Author:      "Alex Miller/AmillionAir",
		Summary:     "Shows full time and date",
		Desc:        "Displays the full date and current time for user.",
		FileName:    "date_time_clock.star",
		PackageName: "datetimeclock",
		Source:  source,
	}
}
