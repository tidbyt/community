// Package tcatbusarrivals provides details for the TCAT Bus Arrivals applet.
package tcatbusarrivals

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed tcat_bus_arrivals.star
var source []byte

// New creates a new instance of the TCAT Bus Arrivals applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "tcat-bus-arrivals",
		Name:        "TCAT Bus Arrivals",
		Author:      "Harry Samuels",
		Summary:     "Show TCAT arrival times",
		Desc:        "Display Arrival Times for TCAT Ithaca Buses at a Specific Stop.",
		FileName:    "tcat_bus_arrivals.star",
		PackageName: "tcatbusarrivals",
		Source:  source,
	}
}
