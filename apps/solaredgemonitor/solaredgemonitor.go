// Package solaredgemonitor provides details for the SolarEdge Monitor applet.
package solaredgemonitor

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed solaredge_monitor.star
var source []byte

// New creates a new instance of the SolarEdge Monitor applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "solaredge-monitor",
		Name:        "SolarEdge Monitor",
		Author:      "Marcus Better",
		Summary:     "PV system monitor",
		Desc:        "Energy production and consumption monitor for your SolarEdge solar panels.",
		FileName:    "solaredge_monitor.star",
		PackageName: "solaredgemonitor",
		Source:  source,
	}
}
