// Package USHolidayCountdown provides details for the US Holiday Countdown applet.
package USHolidayCountdown

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed Holiday_Countdown.star
var source []byte

// New creates a new instance of the US Holiday Countdown applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "holiday-countdown",
		Name:        "US Holiday Countdown",
		Author:      "Alex Miller",
		Summary:     "Countdown to Nearest USA Holiday",
		Desc:        "Counts down days to nearest holiday for USA",
		FileName:    "Holiday_Countdown.star",
		PackageName: "USHolidayCountdown",
		Source:  source,
	}
}
